
public protocol Server {
    associatedtype E: APIError = APIError.Standard
    associatedtype Request

    var decoding: Decoding { get }
    var encoding: Encoding { get }
    var configureRequest: (inout Request, Endpoint) throws -> Void { get }
}
