import FTAPIKit
import Foundation

final class MockupAPIAdapterDelegate: APIAdapterDelegate {
    func apiAdapter(_ apiAdapter: APIAdapter, willRequest request: URLRequest, to endpoint: APIEndpoint, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        if endpoint.authorized {
            var newRequest = request
            newRequest.addValue("Bearer " + UUID().uuidString, forHTTPHeaderField: "Authorization")
            completion(.success(newRequest))
        } else {
            completion(.success(request))
        }
    }

    func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt) {
    }
}
