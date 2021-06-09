#if swift(>=5.5)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension URLServer {
    func call(endpoint: Endpoint) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            call(endpoint: endpoint) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func call(data endpoint: Endpoint) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            call(data: endpoint) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func call<EP: ResponseEndpoint>(response endpoint: EP) async throws -> EP.Response {
        return try await withCheckedThrowingContinuation { continuation in
            call(response: endpoint) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
#endif
