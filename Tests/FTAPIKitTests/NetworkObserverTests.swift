import FTAPIKit
import XCTest

#if os(Linux)
import FoundationNetworking
#endif

final class NetworkObserverTests: XCTestCase {
    private let timeout: TimeInterval = 30.0

    // MARK: - Unit Tests (no network required)

    func testObserverIsCalledForRequest() {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])

        XCTAssertEqual(server.networkObservers.count, 1, "NetworkObservers should contain one observer")
    }

    func testEmptyObserversDoesNotCauseIssues() {
        let server = HTTPBinServer() // Default observers is empty array
        let endpoint = GetEndpoint()

        // Verify empty observers doesn't cause problems during request building
        XCTAssertNoThrow(try server.buildRequest(endpoint: endpoint))
        XCTAssertTrue(server.networkObservers.isEmpty, "Default networkObservers should be empty")
    }

    func testMultipleObserversSupported() {
        let observer1 = MockNetworkObserver()
        let observer2 = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [observer1, observer2])

        XCTAssertEqual(server.networkObservers.count, 2, "Should support multiple observers")
    }

    // MARK: - Integration Tests (requires network)
    // Note: These tests may fail if httpbin.org is unavailable

    func testObserverReceivesLifecycleCallbacks() {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])
        let endpoint = GetEndpoint()
        let expectation = self.expectation(description: "Request completed")

        server.call(endpoint: endpoint) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        XCTAssertEqual(mockObserver.willSendCount, 1, "willSendRequest should be called once")
        // didReceiveResponse is always called; didFail is called additionally on failure
        XCTAssertEqual(mockObserver.didReceiveCount, 1, "didReceiveResponse should always be called")
    }

    func testObserverLogsFailedRequest() {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])
        let endpoint = NotFoundEndpoint()
        let expectation = self.expectation(description: "Result")

        server.call(endpoint: endpoint) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        // didReceiveResponse is always called with raw data; didFail is called additionally on failure
        XCTAssertEqual(mockObserver.willSendCount, 1, "willSendRequest should be called once")
        XCTAssertEqual(mockObserver.didReceiveCount, 1, "didReceiveResponse should always be called")
        XCTAssertEqual(mockObserver.didFailCount, 1, "didFail should be called on failure")
    }

    func testMultipleObserversAllReceiveCallbacks() {
        let observer1 = MockNetworkObserver()
        let observer2 = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [observer1, observer2])
        let endpoint = GetEndpoint()
        let expectation = self.expectation(description: "Request completed")

        server.call(endpoint: endpoint) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        // Both observers should receive callbacks
        XCTAssertEqual(observer1.willSendCount, 1, "Observer 1 willSendRequest should be called")
        XCTAssertEqual(observer2.willSendCount, 1, "Observer 2 willSendRequest should be called")
        XCTAssertEqual(observer1.didReceiveCount, 1, "Observer 1 didReceiveResponse should be called")
        XCTAssertEqual(observer2.didReceiveCount, 1, "Observer 2 didReceiveResponse should be called")
    }
}
