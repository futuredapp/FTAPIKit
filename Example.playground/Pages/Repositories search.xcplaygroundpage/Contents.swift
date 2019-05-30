/*:
 # FTAPIKit playground

 ### Build instructions
 - This playground is meant to be used withing Xcode.
 - Do not open this playground directly. Use FTAPIKit.xcworkspace instead.
 - Once you have opened the workspace, build. Make sure build target platform is the same as Playground's current platform.
 */
import Foundation
import FTAPIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true
/*:
 ## Example description
 This example connects to the Github API using credentials provided below and searches all user's repositories for all project using Swift language.


 ## API Adapter declaration

 ### Prepare variables and configuration
 *Fill in credentials of some active github account.*
 */
let username = "your_github_username"
let password = "your_github_password"

/*:
 Authorization method for Github is described in the link below. FTAPIKit doesn't solve authorization challenges on its own and relies on external support from either networking framework provided to FTAPIKit or custom user implementation using FTAPIKit's callbacks and delegates. However, FTAPIKit does not handle any authorization challenges on its own, FTAPIKit's APIEndpoint protocol contains property _authorized_ which indicates, whether authorization challenges do apply for the endpoint.

 Github authorization: https://developer.github.com/v3/auth/#basic-authentication
 */
let credentials = String(format: "%@:%@", username, password).data(using: .utf8)!.base64EncodedString()

let configuration = URLSessionConfiguration.default
configuration.httpAdditionalHeaders = [
    "Authorization": "Basic \(credentials)"
]
/*:
 FTAPIKit has native support for URLSession however feel free to implement support for any networking framework by implementing APIAdapter protocol.
 */
let urlSession = URLSession(configuration: configuration)

/*:
 URL of the Github API.
 */
let baseUrl = URL(string: "https://api.github.com")!

/*:
 Our reference URLSession implementation of APIAdapter uses JSON decoder/encoder. You may use custom decoders/encoders but you have to implement your own URLSession conformance.
 */
let jsonDecoder = JSONDecoder()
jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

/*:
 ### Instantiate APIAdapter

 APIAdapter is interface through which user executes all rest requests.

 We recommend passing any API adapters references using APIAdapter protocol and we recommend usage of APIAdapterDelegate for expanding functionality of API adapters beyond functionality provided by FTAPIKit and networking service implementing APIAdapter.

 (There is an exception in the reference implementation for task canceling. Reference implementation of URLSession implements this functionality by dataTask<E>(response:creation:completion:) method.)
 */

let apiAdapter: APIAdapter = URLSessionAPIAdapter(baseUrl: baseUrl, jsonDecoder: jsonDecoder, urlSession: urlSession)

/*:
 ## Endpoint model

 We use _search_ endpoint as an example. The endpoint is described in the link below.
 Github search endpoint: https://developer.github.com/v3/search/#search-repositories
*/

/*:
 ### Response declaration

 Only requirement for response type is to conform protocol Decodable. As you can see, we omit a lot of properties described in Github API (provided by link above).

 Similarly, only requirement for request type is to conform protocol Encodable.
 */
struct Repository: Decodable {
    let name: String
    let stargazersCount: UInt
}

struct RepositoriesEndpointResponse: Decodable {
    let items: [Repository]
}

/*:
 ### Endpoint declaration

 FTAPIKit endpoint model consists of three main protocols:
 - APIEndpoint defines behavior of general endpoint under FTAPIKit (this endpoint can be executed on it's own)
 - APIRequestEndpoint extends implementation of APIEndpoint for endpoints with encodable requests
 - APIResponseEndpoint extends implementation of APIEndpoint for endpoints with decodable responses
 (APIRequestResponseEndpoint is union of APIRequestEndpoint and APIResponseEndpoint)

 Note:
 None of properties specified by protocols mentioned above is optional. We do, however, provide default implementations for some of those properties in order to shorten the code. Default values were arbitrary decided by us based on our experience and are not founded in any standard. For complete list of properties and default values please visit APIEndpoint.swift which is completely documented and meant to be used as reference.
 */
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

/*:
 ## Endpoint execution

 Execution of an task is initiated by calling of request<E>(response:completion:) for decodable APIResponseEndpoint instances and request(data:completion:) for general APIEndpoints.

 In case user would like to use promises instead of closures, we provide PromiseKit extension as a subspec.
 */
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
