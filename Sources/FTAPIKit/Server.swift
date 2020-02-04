
public protocol Server {
    associatedtype ErrorType: APIError = APIError.Standard
    associatedtype Request

    var decoding: Decoding { get }
    var encoding: Encoding { get }
    var requestBuilder: (Self, Endpoint) throws -> Request { get }
}
