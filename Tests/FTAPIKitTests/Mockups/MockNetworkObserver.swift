import Foundation
import FTAPIKit

struct MockContext: Sendable {
    let requestId: String
    let startTime: Date
}

final class MockNetworkObserver: NetworkObserver, @unchecked Sendable {
    var willSendCount = 0
    var didReceiveCount = 0
    var didFailCount = 0
    var lastRequestId: String?

    func willSendRequest(_ request: URLRequest) -> MockContext {
        willSendCount += 1
        let context = MockContext(requestId: UUID().uuidString, startTime: Date())
        lastRequestId = context.requestId
        return context
    }

    func didReceiveResponse(for request: URLRequest, response: URLResponse?, data: Data?, context: MockContext) {
        didReceiveCount += 1
    }

    func didFail(request: URLRequest, error: Error, context: MockContext) {
        didFailCount += 1
    }
}
