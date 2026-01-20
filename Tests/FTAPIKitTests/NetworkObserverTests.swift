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

    func testEmptyObserversDoesNotCauseIssues() async throws {
        let server = HTTPBinServer() // Default observers is empty array
        let endpoint = GetEndpoint()

        // Verify empty observers doesn't cause problems during request building
        _ = try await server.buildRequest(endpoint: endpoint)
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

    func testObserverReceivesLifecycleCallbacks() async throws {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])
        let endpoint = GetEndpoint()

        try await server.call(endpoint: endpoint)

        XCTAssertEqual(mockObserver.willSendCount, 1, "willSendRequest should be called once")
        // didReceiveResponse is always called; didFail is called additionally on failure
        XCTAssertEqual(mockObserver.didReceiveCount, 1, "didReceiveResponse should always be called")
    }

    func testObserverLogsFailedRequest() async {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])
        let endpoint = NotFoundEndpoint()

        // Request is expected to fail (404)
        try? await server.call(endpoint: endpoint)

        // didReceiveResponse is always called with raw data; didFail is called additionally on failure
        XCTAssertEqual(mockObserver.willSendCount, 1, "willSendRequest should be called once")
        XCTAssertEqual(mockObserver.didReceiveCount, 1, "didReceiveResponse should always be called")
        XCTAssertEqual(mockObserver.didFailCount, 1, "didFail should be called on failure")
    }

    func testMultipleObserversAllReceiveCallbacks() async throws {
        let observer1 = MockNetworkObserver()
        let observer2 = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [observer1, observer2])
        let endpoint = GetEndpoint()

        try await server.call(endpoint: endpoint)

        // Both observers should receive callbacks
        XCTAssertEqual(observer1.willSendCount, 1, "Observer 1 willSendRequest should be called")
        XCTAssertEqual(observer2.willSendCount, 1, "Observer 2 willSendRequest should be called")
        XCTAssertEqual(observer1.didReceiveCount, 1, "Observer 1 didReceiveResponse should be called")
        XCTAssertEqual(observer2.didReceiveCount, 1, "Observer 2 didReceiveResponse should be called")
    }
}
