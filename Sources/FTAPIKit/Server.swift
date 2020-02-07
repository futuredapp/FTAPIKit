
public protocol Server {
    associatedtype Request

    var decoding: Decoding { get }
    var encoding: Encoding { get }
    var requestBuilder: (Self, Endpoint) throws -> Request { get }
}
