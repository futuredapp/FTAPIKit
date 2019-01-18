
import Foundation
import FTAPIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let username = "your_github_username"
let password = "your_github_password"
let baseUrl = URL(string: "https://api.github.com")!

// Data models
struct Repository: Decodable {
    let name: String
    let stargazersCount: UInt
}

struct RepositoriesEndpointResponse: Decodable {
    let items: [Repository]
}

// Define api response endpoint
struct RepositoriesEndpoint: APIResponseEndpoint {
    typealias Response = RepositoriesEndpointResponse

    let method: HTTPMethod = .get
    let path: String = "/search/repositories"
    let type: RequestType = .urlQuery
    let authorized: Bool = true
    let parameters: HTTPParameters

    init(query: String) {
        self.parameters = [
            "q": query,
            "sort": "stars",
            "order": "desc"
        ]
    }
}

let credentials = String(format: "%@:%@", username, password).data(using: .utf8)!.base64EncodedString()

let configuration = URLSessionConfiguration.default
configuration.httpAdditionalHeaders = [
    "Authorization": "Basic \(credentials)"
]
let urlSession = URLSession(configuration: configuration)

let jsonDecoder = JSONDecoder()
jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

let apiAdapter = URLSessionAPIAdapter(baseUrl: baseUrl, jsonDecoder: jsonDecoder, urlSession: urlSession)

apiAdapter.request(response: RepositoriesEndpoint(query: "language:swift")) { result in
    switch result {
    case .error(let error):
        print(error)
    case .value(let value):
        value.items.forEach { repository in
            print("\(repository.name): \(repository.stargazersCount)")
        }
    }
}
