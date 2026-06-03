use std::io::{BufRead, BufReader, Write};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicI32, Ordering};

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

    let ffmpeg_args = build_ffmpeg_args(&args);
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
            println!("{{\"type\":\"error\",\"message\":\"{msg}\"}}");
            std::process::exit(1);
        }
    };

    #[cfg(unix)]
    FFMPEG_CHILD_PID.store(child.id() as i32, Ordering::SeqCst);

    let ffmpeg_pid = child.id();
    println!(
        "{{\"type\":\"started\",\"ffmpeg_pid\":{}}}",
        ffmpeg_pid
    );
    let _ = std::io::stdout().flush();

    let stderr = child.stderr.take().expect("no stderr");
    let reader = BufReader::new(stderr);
    let mut duration: Option<f64> = None;
    let mut ffmpeg_stderr: Vec<String> = Vec::new();

    for line in reader.lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => break,
        };

        ffmpeg_stderr.push(line.clone());

        if duration.is_none() {
            if let Some(d) = parse_duration(&line) {
                duration = Some(d);
            }
        }

        if let Some(time) = parse_time(&line) {
            if let Some(dur) = duration {
                if dur > 0.0 {
                    let pct = ((time / dur) * 100.0 * 10.0).round() / 10.0;
                    let speed = parse_speed(&line).unwrap_or(0.0);
                    let remaining = (dur - time).max(0.0);
                    let eta_seconds = if speed > 0.01 {
                        remaining / speed
                    } else {
                        0.0
                    };
                    let json = serde_json::json!({
                        "type": "progress",
                        "percent": pct,
                        "eta_seconds": eta_seconds,
                        "time": format_time(time),
                        "speed": format!("{speed:.1}x"),
                    });
                    println!("{json}");
                    let _ = std::io::stdout().flush();
                }
            }
        }
    }

    let status = match child.wait() {
        Ok(s) => s,
        Err(e) => {
            let msg = format!("failed to wait for ffmpeg: {e}");
            eprintln!("{msg}");
            println!("{{\"type\":\"error\",\"message\":\"{msg}\"}}");
            std::process::exit(1);
        }
    };

    if status.success() {
        println!("{{\"type\":\"done\"}}");
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
        println!("{{\"type\":\"error\",\"message\":\"ffmpeg exited with code {code}: {detail}\"}}");
        std::process::exit(code);
    }
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

fn build_ffmpeg_args(args: &Args) -> Vec<String> {
    let mut cmd: Vec<String> = Vec::new();

    cmd.push("-i".to_string());
    cmd.push(args.input.clone());
    cmd.push("-y".to_string());
    cmd.push("-nostdin".to_string());

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
            cmd.extend(["-codec:a".into(), "vorbis".into()]);
            if let Some(ref b) = args.bitrate {
                cmd.extend(["-b:a".into(), b.clone()]);
            }
        }
        "wav" => {
            cmd.extend(["-codec:a".into(), "pcm_s16le".into()]);
        }
        "mp4" | "mkv" | "avi" => {
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
        "ogv" => {
        }
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
        "ico" | "pdf" | "svg" => {
            cmd.extend(["-frames:v".into(), "1".into()]);
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
        "mp4" | "mkv" | "avi" | "webm" | "ogv" | "gif"
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

fn parse_duration(line: &str) -> Option<f64> {
    let re = regex::Regex::new(r"Duration:\s*(\d{2}):(\d{2}):(\d{2})\.(\d{2})").ok()?;
    let caps = re.captures(line)?;
    let h: f64 = caps[1].parse().ok()?;
    let m: f64 = caps[2].parse().ok()?;
    let s: f64 = caps[3].parse().ok()?;
    let c: f64 = caps[4].parse().ok()?;
    Some(h * 3600.0 + m * 60.0 + s + c / 100.0)
}

fn parse_time(line: &str) -> Option<f64> {
    let re = regex::Regex::new(r"time=\s*(\d{2}):(\d{2}):(\d{2})\.(\d{2})").ok()?;
    if let Some(caps) = re.captures(line) {
        let h: f64 = caps[1].parse().ok()?;
        let m: f64 = caps[2].parse().ok()?;
        let s: f64 = caps[3].parse().ok()?;
        let c: f64 = caps[4].parse().ok()?;
        Some(h * 3600.0 + m * 60.0 + s + c / 100.0)
    } else {
        None
    }
}

fn parse_speed(line: &str) -> Option<f64> {
    let re = regex::Regex::new(r"speed=\s*(\d+\.?\d*)x").ok()?;
    let caps = re.captures(line)?;
    caps[1].parse().ok()
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
