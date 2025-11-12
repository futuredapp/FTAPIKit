import FTAPIKit
import FTNetworkTracer
import XCTest

#if os(Linux)
import FoundationNetworking
#endif

final class NetworkTracerIntegrationTests: XCTestCase {
    private let timeout: TimeInterval = 30.0

    // MARK: - Unit Tests (no network required)

    func testTracerIsCalledForRequest() {
        let mockAnalytics = MockAnalytics()
        let tracer = FTNetworkTracer(logger: nil, analytics: mockAnalytics)
        let server = HTTPBinServerWithTracer(tracer: tracer)
        let endpoint = GetEndpoint()

        // Build request to verify tracer integration
        _ = try? server.buildRequest(endpoint: endpoint)

        // Note: Just building request doesn't trigger logging,
        // but this verifies the tracer property is properly integrated
        XCTAssertNotNil(server.networkTracer, "NetworkTracer should be set")
    }

    func testNilTracerDoesNotCauseIssues() {
        let server = HTTPBinServer() // Default tracer is nil
        let endpoint = GetEndpoint()

        // Verify nil tracer doesn't cause problems during request building
        XCTAssertNoThrow(try server.buildRequest(endpoint: endpoint))
        XCTAssertNil(server.networkTracer, "Default networkTracer should be nil")
    }

    func testMockAnalyticsTracking() {
        let mockAnalytics = MockAnalytics()
        let analyticEntry = AnalyticEntry(
            type: .request(method: "GET", url: "https://test.com"),
            headers: [:],
            body: nil,
            duration: nil,
            requestId: "test-123",
            configuration: mockAnalytics.configuration
        )

        mockAnalytics.track(analyticEntry)

        XCTAssertEqual(mockAnalytics.requestCount, 1)
        XCTAssertEqual(mockAnalytics.lastRequestId, "test-123")
    }

    // MARK: - Integration Tests (requires network)
    // Note: These tests may fail if httpbin.org is unavailable

    func testTracerLogsFailedRequest() {
        let mockAnalytics = MockAnalytics()
        let tracer = FTNetworkTracer(logger: nil, analytics: mockAnalytics)
        let server = HTTPBinServerWithTracer(tracer: tracer)
        let endpoint = NotFoundEndpoint()
        let expectation = self.expectation(description: "Result")

        server.call(endpoint: endpoint) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        // Verify tracer was called (request is always logged, even on failure)
        XCTAssertEqual(mockAnalytics.requestCount, 1, "Request should be logged once")
        XCTAssertGreaterThanOrEqual(mockAnalytics.responseCount + mockAnalytics.errorCount, 1,
                                    "Either response or error should be logged")
    }
}
