import Foundation

struct URLRequestBuilder<S: URLServer> {
    let server: S
    let endpoint: Endpoint

    func build() throws -> URLRequest {
        let url = server.baseUri
            .appendingPathComponent(endpoint.path)
            .appendingQuery(parameters: endpoint.query)
        var request = URLRequest(url: url)

        request.httpMethod = endpoint.method.description
        request.allHTTPHeaderFields = endpoint.headers
        try server.encoding.configure(request: &request)
        try server.configureRequest(&request, endpoint)
        return request
    }
}
