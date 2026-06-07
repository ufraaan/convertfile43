use std::io::{BufReader, Read, Write};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, AtomicI32, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

#[cfg(unix)]
static FFMPEG_CHILD_PID: AtomicI32 = AtomicI32::new(0);

fn main() {
    #[cfg(unix)]
    install_signal_handlers();
    let args = match parse_args() {
        Ok(a) => a,
        Err(e) => {
            eprintln!("error: {e}");
            std::process::exit(1);
        }
    };

    let progress_file = std::env::temp_dir().join(format!("ffconv-{}.progress", std::process::id()));
    let _ = std::fs::remove_file(&progress_file);

    let ffmpeg_args = build_ffmpeg_args(&args, Some(&progress_file));
    let mut child = match Command::new(&args.ffmpeg)
        .args(&ffmpeg_args)
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            let msg = format!("failed to spawn ffmpeg: {e}");
            eprintln!("{msg}");
            emit_json(&serde_json::json!({"type": "error", "message": msg}));
            std::process::exit(1);
        }
    };

    #[cfg(unix)]
    FFMPEG_CHILD_PID.store(child.id() as i32, Ordering::SeqCst);

    let ffmpeg_pid = child.id();
    emit_json(&serde_json::json!({
        "type": "started",
        "ffmpeg_pid": ffmpeg_pid
    }));

    let duration: Arc<Mutex<Option<f64>>> = Arc::new(Mutex::new(None));
    let poll_running = Arc::new(AtomicBool::new(true));
    let last_percent: Arc<Mutex<f64>> = Arc::new(Mutex::new(-1.0));

    let poll_duration = duration.clone();
    let poll_last = last_percent.clone();
    let poll_path = progress_file.clone();
    let poll_flag = poll_running.clone();
    let poll_thread = thread::spawn(move || {
        while poll_flag.load(Ordering::Relaxed) {
            if let Ok(text) = std::fs::read_to_string(&poll_path) {
                let dur = *poll_duration.lock().unwrap();
                if let Some(event) = progress_from_progress_file(&text, dur) {
                    emit_progress_if_changed(&event, &poll_last);
                }
            }
            thread::sleep(Duration::from_millis(250));
        }
    });

    let stderr = child.stderr.take().expect("no stderr");
    let mut reader = BufReader::new(stderr);
    let mut pending = String::new();
    let mut buf = [0u8; 8192];
    let mut ffmpeg_stderr: Vec<String> = Vec::new();

    loop {
        let n = match reader.read(&mut buf) {
            Ok(0) => break,
            Ok(n) => n,
            Err(_) => break,
        };
        pending.push_str(&String::from_utf8_lossy(&buf[..n]));
        drain_stderr_lines(&mut pending, |line| {
            ffmpeg_stderr.push(line.to_string());

            let mut dur_guard = duration.lock().unwrap();
            if dur_guard.is_none() {
                if let Some(d) = parse_duration(line) {
                    *dur_guard = Some(d);
                }
            }
            let dur = *dur_guard;

            if let Some(event) = progress_from_stderr_line(line, dur) {
                emit_progress_if_changed(&event, &last_percent);
            }
        });
    }

    if !pending.trim().is_empty() {
        let line = pending.trim();
        ffmpeg_stderr.push(line.to_string());
        let mut dur_guard = duration.lock().unwrap();
        if dur_guard.is_none() {
            if let Some(d) = parse_duration(line) {
                *dur_guard = Some(d);
            }
        }
        if let Some(event) = progress_from_stderr_line(line, *dur_guard) {
            emit_progress_if_changed(&event, &last_percent);
        }
    }

    poll_running.store(false, Ordering::Relaxed);
    let _ = poll_thread.join();
    let _ = std::fs::remove_file(&progress_file);

    let status = match child.wait() {
        Ok(s) => s,
        Err(e) => {
            let msg = format!("failed to wait for ffmpeg: {e}");
            eprintln!("{msg}");
            emit_json(&serde_json::json!({"type": "error", "message": msg}));
            std::process::exit(1);
        }
    };

    if status.success() {
        emit_json(&serde_json::json!({"type": "done"}));
    } else {
        let code = status.code().unwrap_or(-1);
        let detail = ffmpeg_stderr
            .iter()
            .rev()
            .take(10)
            .cloned()
            .collect::<Vec<_>>()
            .join(" | ");
        eprintln!("ffmpeg exited with code {code}: {detail}");
        emit_json(&serde_json::json!({
            "type": "error",
            "message": format!("ffmpeg exited with code {code}: {detail}")
        }));
        std::process::exit(code);
    }
}

struct ProgressEvent {
    percent: f64,
    eta_seconds: f64,
    time: String,
    speed: String,
}

fn emit_json(value: &serde_json::Value) {
    println!("{value}");
    let _ = std::io::stdout().flush();
}

fn emit_progress_if_changed(event: &ProgressEvent, last_percent: &Mutex<f64>) {
    let mut last = last_percent.lock().unwrap();
    if (event.percent - *last).abs() < 0.05 && *last >= 0.0 {
        return;
    }
    *last = event.percent;
    emit_json(&serde_json::json!({
        "type": "progress",
        "percent": event.percent,
        "eta_seconds": event.eta_seconds,
        "time": event.time,
        "speed": event.speed,
    }));
}

fn drain_stderr_lines(pending: &mut String, mut on_line: impl FnMut(&str)) {
    loop {
        let split_at = pending.find('\n').or_else(|| pending.find('\r'));
        let Some(idx) = split_at else {
            break;
        };
        let line = pending[..idx].trim().to_string();
        pending.drain(..=idx);
        if !line.is_empty() {
            on_line(&line);
        }
    }
}

fn progress_from_stderr_line(line: &str, duration: Option<f64>) -> Option<ProgressEvent> {
    let dur = duration?;
    if dur <= 0.0 {
        return None;
    }
    let time = parse_time(line)?;
    let pct = ((time / dur) * 100.0 * 10.0).round() / 10.0;
    let speed = parse_speed(line).unwrap_or(0.0);
    let remaining = (dur - time).max(0.0);
    let eta_seconds = if speed > 0.01 { remaining / speed } else { 0.0 };
    Some(ProgressEvent {
        percent: pct,
        eta_seconds,
        time: format_time(time),
        speed: format!("{speed:.1}x"),
    })
}

fn progress_from_progress_file(content: &str, duration: Option<f64>) -> Option<ProgressEvent> {
    let dur = duration?;
    if dur <= 0.0 {
        return None;
    }

    let mut out_time_ms: Option<f64> = None;
    let mut speed: Option<f64> = None;
    let mut progress_state: Option<String> = None;

    for line in content.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        match key {
            "out_time_ms" => out_time_ms = value.parse().ok(),
            "speed" => speed = parse_speed_token(value),
            "progress" => progress_state = Some(value.to_string()),
            _ => {}
        }
    }

    if progress_state.as_deref() == Some("end") {
        return None;
    }

    let out_ms = out_time_ms?;
    let dur_ms = dur * 1000.0;
    if dur_ms <= 0.0 {
        return None;
    }

    let pct = ((out_ms / dur_ms) * 100.0 * 10.0).round() / 10.0;
    let time_secs = out_ms / 1000.0;
    let speed_val = speed.unwrap_or(0.0);
    let remaining = (dur - time_secs).max(0.0);
    let eta_seconds = if speed_val > 0.01 {
        remaining / speed_val
    } else {
        0.0
    };

    Some(ProgressEvent {
        percent: pct.min(100.0),
        eta_seconds,
        time: format_time(time_secs),
        speed: format!("{speed_val:.1}x"),
    })
}

fn parse_speed_token(value: &str) -> Option<f64> {
    let trimmed = value.trim();
    let numeric = trimmed.trim_end_matches('x').trim();
    numeric.parse().ok()
}

struct Args {
    ffmpeg: String,
    input: String,
    output: String,
    output_type: String,
    quality: Option<u32>,
    bitrate: Option<String>,
    sample_rate: Option<String>,
    channels: Option<u32>,
    scale: Option<String>,
    fps: Option<u32>,
}

fn parse_args() -> Result<Args, String> {
    let raw: Vec<String> = std::env::args().collect();
    if raw.len() < 2 || raw[1] == "--help" || raw[1] == "-h" {
        return Err("usage: ffconv --ffmpeg <path> --input <path> --output <path> --output-type <type> [options]

options:
  --ffmpeg <path>       path to ffmpeg binary
  --input <path>        input file path
  --output <path>       output file path
  --output-type <type>  one of: mp3, aac, flac, ogg, wav, mp4, mkv, avi, webm,
                        ogv, gif, jpg, png, webp, avif, ico, pdf, svg
  --quality <0-100>     output quality
  --bitrate <k>         audio/video bitrate (e.g. 192k, 2000k)
  --sample-rate <hz>    audio sample rate
  --channels <n>        audio channel count
  --scale <WxH>         video scale (e.g. 1920x1080)
  --fps <n>             video framerate"
            .to_string());
    }

    let mut ffmpeg = None;
    let mut input = None;
    let mut output = None;
    let mut output_type = None;
    let mut quality = None;
    let mut bitrate = None;
    let mut sample_rate = None;
    let mut channels = None;
    let mut scale = None;
    let mut fps = None;

    let mut i = 1;
    while i < raw.len() {
        match raw[i].as_str() {
            "--ffmpeg" => {
                i += 1;
                ffmpeg = Some(raw[i].clone());
            }
            "--input" => {
                i += 1;
                input = Some(raw[i].clone());
            }
            "--output" => {
                i += 1;
                output = Some(raw[i].clone());
            }
            "--output-type" => {
                i += 1;
                output_type = Some(raw[i].clone());
            }
            "--quality" => {
                i += 1;
                quality = Some(raw[i].parse().map_err(|_| "invalid quality")?);
            }
            "--bitrate" => {
                i += 1;
                bitrate = Some(raw[i].clone());
            }
            "--sample-rate" => {
                i += 1;
                sample_rate = Some(raw[i].clone());
            }
            "--channels" => {
                i += 1;
                channels = Some(raw[i].parse().map_err(|_| "invalid channels")?);
            }
            "--scale" => {
                i += 1;
                scale = Some(raw[i].clone());
            }
            "--fps" => {
                i += 1;
                fps = Some(raw[i].parse().map_err(|_| "invalid fps")?);
            }
            other => return Err(format!("unknown flag: {other}")),
        }
        i += 1;
    }

    Ok(Args {
        ffmpeg: ffmpeg.ok_or("--ffmpeg is required")?,
        input: input.ok_or("--input is required")?,
        output: output.ok_or("--output is required")?,
        output_type: output_type.ok_or("--output-type is required")?,
        quality,
        bitrate,
        sample_rate,
        channels,
        scale,
        fps,
    })
}

fn uses_progress_streaming(output_type: &str) -> bool {
    matches!(
        output_type,
        "mp3" | "aac" | "flac" | "ogg" | "wav" | "mp4" | "mkv" | "avi" | "webm" | "ogv" | "gif"
    )
}

fn build_ffmpeg_args(args: &Args, progress_file: Option<&PathBuf>) -> Vec<String> {
    let mut cmd: Vec<String> = Vec::new();

    cmd.push("-i".to_string());
    cmd.push(args.input.clone());
    cmd.push("-y".to_string());
    cmd.push("-nostdin".to_string());

    if uses_progress_streaming(&args.output_type) {
        cmd.push("-stats_period".to_string());
        cmd.push("0.5".to_string());
        if let Some(path) = progress_file {
            cmd.push("-progress".to_string());
            cmd.push(path.to_string_lossy().into_owned());
        }
    }

    match args.output_type.as_str() {
        "mp3" => {
            cmd.extend(["-codec:a".into(), "libmp3lame".into()]);
            if let Some(ref b) = args.bitrate {
                cmd.extend(["-b:a".into(), b.clone()]);
            }
        }
        "aac" => {
            cmd.extend(["-codec:a".into(), "aac".into()]);
            if let Some(ref b) = args.bitrate {
                cmd.extend(["-b:a".into(), b.clone()]);
            }
        }
        "flac" => {
            cmd.extend(["-codec:a".into(), "flac".into()]);
        }
        "ogg" => {
            cmd.extend(["-codec:a".into(), "libvorbis".into()]);
            if let Some(ref b) = args.bitrate {
                cmd.extend(["-b:a".into(), b.clone()]);
            }
        }
        "wav" => {
            cmd.extend(["-codec:a".into(), "pcm_s16le".into()]);
        }
        "mp4" | "mkv" | "mov" | "avi" => {
            cmd.extend(["-codec:v".into(), "h264_videotoolbox".into()]);
            cmd.extend(["-codec:a".into(), "aac".into()]);
            if let Some(ref s) = args.scale {
                cmd.extend(["-vf".into(), format!("scale={s}")]);
            }
            if let Some(f) = args.fps {
                cmd.extend(["-r".into(), format!("{f}")]);
            }
        }
        "webm" => {
            cmd.extend(["-codec:v".into(), "libvpx-vp9".into()]);
            cmd.extend(["-codec:a".into(), "libopus".into()]);
            if let Some(ref s) = args.scale {
                cmd.extend(["-vf".into(), format!("scale={s}")]);
            }
        }
        "ogv" => {}
        "gif" => {
            let fps = args.fps.unwrap_or(15);
            let scale = args.scale.as_deref().unwrap_or("800:-1");
            cmd.extend([
                "-vf".into(),
                format!("fps={fps},scale={scale}:flags=lanczos"),
            ]);
        }
        "jpg" => {
            cmd.extend(["-frames:v".into(), "1".into(), "-codec:v".into(), "mjpeg".into()]);
            if let Some(q) = args.quality {
                let qv = (2.max(31.min(31 - ((q as f64 / 100.0) * 29.0) as i32))).to_string();
                cmd.extend(["-q:v".into(), qv]);
            }
            if let Some(ref s) = args.scale {
                cmd.extend(["-vf".into(), format!("scale={s}")]);
            }
        }
        "png" => {
            cmd.extend(["-frames:v".into(), "1".into(), "-codec:v".into(), "png".into()]);
            if args.quality.is_some() {
                let level = (1.max(9.min(((args.quality.unwrap_or(80) as f64) / 11.0) as i32))).to_string();
                cmd.extend(["-compression_level".into(), level]);
            }
            if let Some(ref s) = args.scale {
                cmd.extend(["-vf".into(), format!("scale={s}")]);
            }
        }
        "webp" => {
            cmd.extend(["-frames:v".into(), "1".into(), "-codec:v".into(), "libwebp".into()]);
            if let Some(q) = args.quality {
                cmd.extend(["-q:v".into(), q.to_string()]);
            }
            if let Some(ref s) = args.scale {
                cmd.extend(["-vf".into(), format!("scale={s}")]);
            }
        }
        "avif" => {
            cmd.extend(["-frames:v".into(), "1".into(), "-codec:v".into(), "libsvtav1".into()]);
            if let Some(q) = args.quality {
                cmd.extend(["-q:v".into(), q.to_string()]);
            }
            if let Some(ref s) = args.scale {
                cmd.extend(["-vf".into(), format!("scale={s}")]);
            }
        }
        "ico" | "svg" => {
            cmd.extend(["-frames:v".into(), "1".into()]);
        }
        "pdf" => {
            cmd.extend(["-frames:v".into(), "1".into(), "-f".into(), "image2".into()]);
            if let Some(ref s) = args.scale {
                cmd.extend(["-vf".into(), format!("scale={s}")]);
            }
        }
        other => {
            eprintln!("warning: unknown output type '{other}', passing through raw args");
            cmd.push(args.output.clone());
            return cmd;
        }
    }

    let is_audio = matches!(args.output_type.as_str(), "mp3" | "aac" | "flac" | "ogg" | "wav");
    let is_video = matches!(
        args.output_type.as_str(),
        "mp4" | "mkv" | "mov" | "avi" | "webm" | "ogv" | "gif"
    );
    if is_audio || is_video {
        if let Some(ref sr) = args.sample_rate {
            cmd.extend(["-ar".into(), sr.clone()]);
        }
        if let Some(ch) = args.channels {
            cmd.extend(["-ac".into(), ch.to_string()]);
        }
    }

    let is_image = matches!(args.output_type.as_str(), "jpg" | "png" | "webp" | "avif" | "ico" | "svg");
    if (is_image && args.output_type != "gif") || args.output_type == "pdf" {
        cmd.extend(["-update".into(), "1".into()]);
    }

    cmd.push(args.output.clone());
    cmd
}

fn parse_hms_fractional(caps: regex::Captures<'_>) -> Option<f64> {
    let h: f64 = caps.get(1)?.as_str().parse().ok()?;
    let m: f64 = caps.get(2)?.as_str().parse().ok()?;
    let s: f64 = caps.get(3)?.as_str().parse().ok()?;
    let frac_str = caps.get(4)?.as_str();
    let frac: f64 = frac_str.parse().ok()?;
    let frac_seconds = frac / 10f64.powi(frac_str.len() as i32);
    Some(h * 3600.0 + m * 60.0 + s + frac_seconds)
}

fn parse_duration(line: &str) -> Option<f64> {
    let re = regex::Regex::new(r"Duration:\s*(\d{1,2}):(\d{2}):(\d{2})\.(\d{2,3})").ok()?;
    let caps = re.captures(line)?;
    parse_hms_fractional(caps)
}

fn parse_time(line: &str) -> Option<f64> {
    let re = regex::Regex::new(r"time=\s*(\d{1,2}):(\d{2}):(\d{2})\.(\d{2,3})").ok()?;
    let caps = re.captures(line)?;
    parse_hms_fractional(caps)
}

fn parse_speed(line: &str) -> Option<f64> {
    let re = regex::Regex::new(r"speed=\s*(\d+\.?\d*)x").ok()?;
    let caps = re.captures(line)?;
    caps.get(1)?.as_str().parse().ok()
}

fn format_time(secs: f64) -> String {
    let h = (secs / 3600.0) as u32;
    let m = ((secs % 3600.0) / 60.0) as u32;
    let s = secs % 60.0;
    format!("{h:02}:{m:02}:{s:05.2}")
}

#[cfg(unix)]
fn install_signal_handlers() {
    unsafe extern "C" fn on_signal(sig: libc::c_int) {
        let pid = FFMPEG_CHILD_PID.load(Ordering::SeqCst);
        if pid > 0 {
            libc::kill(pid, libc::SIGTERM);
        }
        libc::_exit(128 + sig);
    }

    unsafe {
        libc::signal(libc::SIGTERM, on_signal as libc::sighandler_t);
        libc::signal(libc::SIGINT, on_signal as libc::sighandler_t);
    }
}
