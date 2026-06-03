import XCTest
@testable import convertfile43

final class ProcessTerminationTests: XCTestCase {
    func test_processTreePIDs_alwaysIncludesRoots() {
        let roots: [pid_t] = [42, 99]
        let tree = Set(ProcessTermination.processTreePIDs(roots: roots))
        XCTAssertTrue(tree.isSuperset(of: roots))
    }

    func test_isRunning_invalidPID_returnsFalse() {
        XCTAssertFalse(ProcessTermination.isRunning(-1))
        XCTAssertFalse(ProcessTermination.isRunning(0))
    }

    func test_terminateAll_emptyRootsIsNoOp() {
        ProcessTermination.terminateAll(roots: [])
    }
}
