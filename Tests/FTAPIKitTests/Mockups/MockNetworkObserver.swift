import Foundation
import FTAPIKit

struct MockContext: Sendable {
    let requestId: String
    let startTime: Date
}

final class MockNetworkObserver: NetworkObserver, @unchecked Sendable {
    private let lock = NSLock()
    private var _willSendCount = 0
    private var _didReceiveCount = 0
    private var _didFailCount = 0
    private var _lastRequestId: String?

    var willSendCount: Int { lock.withLock { _willSendCount } }
    var didReceiveCount: Int { lock.withLock { _didReceiveCount } }
    var didFailCount: Int { lock.withLock { _didFailCount } }
    var lastRequestId: String? { lock.withLock { _lastRequestId } }

    func willSendRequest(_ request: URLRequest) -> MockContext {
        let context = MockContext(requestId: UUID().uuidString, startTime: Date())
        lock.withLock {
            _willSendCount += 1
            _lastRequestId = context.requestId
        }
        return context
    }

    func didReceiveResponse(for request: URLRequest, response: URLResponse?, data: Data?, context: MockContext) {
        lock.withLock { _didReceiveCount += 1 }
    }

    func didFail(request: URLRequest, error: Error, context: MockContext) {
        lock.withLock { _didFailCount += 1 }
    }
}
