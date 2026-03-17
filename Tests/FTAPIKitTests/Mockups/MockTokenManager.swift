import Foundation

/// Thread-safe mock token manager for testing async token refresh patterns.
final class MockTokenManager: @unchecked Sendable {
    private let lock = NSLock()
    private var _currentToken: String = "initial-token"
    private var _refreshCalled = false

    var currentToken: String {
        get { lock.withLock { _currentToken } }
        set { lock.withLock { _currentToken = newValue } }
    }

    var refreshCalled: Bool {
        lock.withLock { _refreshCalled }
    }

    func refreshIfNeeded() async {
        try? await Task.sleep(nanoseconds: 10_000_000)
        lock.withLock {
            _refreshCalled = true
            _currentToken = "refreshed-token-456"
        }
    }

    func getValidToken() async -> String {
        try? await Task.sleep(nanoseconds: 10_000_000)
        lock.withLock {
            _refreshCalled = true
            _currentToken = "refreshed-token"
        }
        return currentToken
    }
}
