import Foundation
import FTAPIKit
import Testing

@Suite
struct NetworkObserverTests {

    @Test
    func observerIsCalledForRequest() {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])
        #expect(server.networkObservers.count == 1, "NetworkObservers should contain one observer")
    }

    @Test
    func emptyObserversDoesNotCauseIssues() async throws {
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        _ = try await server.buildRequest(endpoint: endpoint)
        #expect(server.networkObservers.isEmpty, "Default networkObservers should be empty")
    }

    @Test
    func multipleObserversSupported() {
        let observer1 = MockNetworkObserver()
        let observer2 = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [observer1, observer2])
        #expect(server.networkObservers.count == 2, "Should support multiple observers")
    }

    // MARK: - Integration Tests (requires network)

    @Test
    func observerReceivesLifecycleCallbacks() async throws {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])
        let endpoint = GetEndpoint()

        _ = try await server.call(data: endpoint)

        #expect(mockObserver.willSendCount == 1, "willSendRequest should be called once")
        #expect(mockObserver.didReceiveCount == 1, "didReceiveResponse should always be called")
    }

    @Test
    func observerLogsFailedRequest() async {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])
        let endpoint = NotFoundEndpoint()

        do {
            _ = try await server.call(data: endpoint)
            Issue.record("Expected error for 404 endpoint")
        } catch {
            // Expected error
        }

        #expect(mockObserver.willSendCount == 1, "willSendRequest should be called once")
        #expect(mockObserver.didReceiveCount == 1, "didReceiveResponse should always be called")
        #expect(mockObserver.didFailCount == 1, "didFail should be called on failure")
    }

    @Test
    func observerReceivesResponseBeforeDecodingFailure() async {
        let mockObserver = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [mockObserver])
        let endpoint = DecodingFailureEndpoint()

        do {
            _ = try await server.call(response: endpoint)
            Issue.record("Expected decoding error")
        } catch {
            // Expected decoding error
        }

        #expect(mockObserver.willSendCount == 1, "willSendRequest should be called once")
        #expect(mockObserver.didReceiveCount == 1, "didReceiveResponse should be called even when decoding fails")
        #expect(mockObserver.didFailCount == 1, "didFail should be called for decoding error")
    }

    @Test
    func multipleObserversAllReceiveCallbacks() async throws {
        let observer1 = MockNetworkObserver()
        let observer2 = MockNetworkObserver()
        let server = HTTPBinServerWithObservers(observers: [observer1, observer2])
        let endpoint = GetEndpoint()

        _ = try await server.call(data: endpoint)

        #expect(observer1.willSendCount == 1, "Observer 1 willSendRequest should be called")
        #expect(observer2.willSendCount == 1, "Observer 2 willSendRequest should be called")
        #expect(observer1.didReceiveCount == 1, "Observer 1 didReceiveResponse should be called")
        #expect(observer2.didReceiveCount == 1, "Observer 2 didReceiveResponse should be called")
    }
}
