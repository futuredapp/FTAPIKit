import Foundation

public extension URLServer {
    static func buildStandardRequest(server: Self, endpoint: Endpoint) throws -> URLRequest {
        try URLRequestBuilder(server: server, endpoint: endpoint).build()
    }
}

struct URLRequestBuilder<S: URLServer> {
    public let server: S
    public let endpoint: Endpoint

    init(server: S, endpoint: Endpoint) {
        self.server = server
        self.endpoint = endpoint
    }

    func build() throws -> URLRequest {
        let url = server.baseUri
            .appendingPathComponent(endpoint.path)
            .appendingQuery(parameters: endpoint.query)
        var request = URLRequest(url: url)

        request.httpMethod = endpoint.method.description
        request.allHTTPHeaderFields = endpoint.headers
        try buildBody(to: &request)
        try server.encoding.configure(request: &request)
        return request
    }

    private func buildBody(to request: inout URLRequest) throws {
        switch endpoint {
        case let endpoint as DataEndpoint:
            request.httpBody = endpoint.body
        case let endpoint as AnyRequestEndpoint:
            request.httpBody = try endpoint.body(encoding: server.encoding)
        default:
            break
        }
    }
}
