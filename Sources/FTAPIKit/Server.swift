public protocol Server {
    associatedtype Request

    var decoding: Decoding { get }
    var encoding: Encoding { get }

    func buildRequest(endpoint: Endpoint) throws -> Request
}
