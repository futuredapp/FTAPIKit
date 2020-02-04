
public protocol Server {
    associatedtype ErrorType: APIError = APIError.Standard
    associatedtype Request

    var decoding: Decoding { get }
    var encoding: Encoding { get }
    var configureRequest: (inout Request, Endpoint) throws -> Void { get }
}
