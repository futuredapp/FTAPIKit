import UIKit
import Foundation
import FTAPIKit

let username = "github_username"
let password = "github_password"
let baseUrl = URL(string: "https://api.github.com")!

// Data models
struct Repository: Decodable {
    let name: String
    let stargazersCount: UInt
}

struct SearchResult: Decodable {
    let items: [Repository]
}

// Define api response endpoint
struct RepositoriesEndpoint: APIResponseEndpoint {
    typealias Response = SearchResult

    let method: HTTPMethod = .get
    let path: String = "/search/repositories"
    let type: RequestType = .urlQuery
    let parameters: HTTPParameters
    let authorized: Bool = true
}

// Wraps ApiAdapter and transforms response to provide user with requested data
final class RepositoriesService {
    var apiAdapter: APIAdapter

    init(apiAdapter: APIAdapter) {
        self.apiAdapter = apiAdapter
        self.apiAdapter.delegate = self
    }

    func sortedRepositories(searchString: String, onSuccess: @escaping ([Repository]) -> Void, onError: @escaping (Error) -> Void) {
        let parameters = [
                "q": searchString,
                "sort": "stars",
                "order": "desc"
            ]

        apiAdapter.request(response: RepositoriesEndpoint(parameters: parameters)) { result in
            switch result {
            case .error(let error):
                onError(error)
            case .value(let value):
                onSuccess(value.items)
            }
        }
    }
}

// APIAdapterDelegate protocol confirmance allows to respond on running request count change or to transform request if needed (manage headers, tokens etc.)
extension RepositoriesService: APIAdapterDelegate {
    func apiAdapter(_ apiAdapter: APIAdapter, willRequest request: URLRequest, to endpoint: APIEndpoint, completion: @escaping (APIResult<URLRequest>) -> Void) {
        guard endpoint.authorized else {
            completion(.value(request))
            return
        }

        var updatedRequest = request
        let credentials = String(format: "%@:%@", username, password).data(using: .utf8)!
        let base64Data = credentials.base64EncodedString()
        updatedRequest.addValue("Basic \(base64Data)", forHTTPHeaderField: "Authorization")
        completion(.value(updatedRequest))
    }

    // Show activity indicator, if there is at least one running request
    func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt) {
        let isVisible = UIApplication.shared.isNetworkActivityIndicatorVisible
        if runningRequestCount > 0, !isVisible {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        } else if runningRequestCount < 1 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}

let jsonDecoder = JSONDecoder()
jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

let repositoriesService: RepositoriesService = RepositoriesService(apiAdapter: URLSessionAPIAdapter(baseUrl: baseUrl, jsonDecoder: jsonDecoder))

// Search for repositories containing "swift" and sorted by number of received stars
repositoriesService.sortedRepositories(searchString: "swift", onSuccess: { repositories in
    repositories.forEach { repo in
        print("\(repo.name): \(repo.stargazersCount)")
    }
}, onError: { error in
    print(error)
})

