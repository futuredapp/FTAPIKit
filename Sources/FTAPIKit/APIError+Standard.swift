import Foundation

#if os(Linux)
import FoundationNetworking 
#endif

/// Standard API error returned in `APIResult` when no custom error
/// was parsed in the `APIAdapter` first and the response from server
/// was invalid.
public enum APIErrorStandard: APIError {
    /// Error raised by URLSession.
    case connection(URLError)
    case encoding(EncodingError)
    case decoding(DecodingError)
    /// Status code error when the response status code
    /// is larger or equal to 500 and less than 600.
    case server(Int, URLResponse, Data?)
    /// Status code error when the response status code
    /// is larger or equal to 400 and less than 500.
    case client(Int, URLResponse, Data?)
    case unhandled(data: Data?, response: URLResponse?, error: Error?)

    public init?(data: Data?, response: URLResponse?, error: Error?, decoding: Decoding) {
        switch (data, response as? HTTPURLResponse, error) {
        case let (_, _, error as URLError):
            self = .connection(error)
        case let (_, _, error as EncodingError):
            self = .encoding(error)
        case let (_, _, error as DecodingError):
            self = .decoding(error)
        case let (data, response?, nil) where 400..<500 ~= response.statusCode:
            self = .client(response.statusCode, response, data)
        case let (data, response?, nil) where 500..<600 ~= response.statusCode:
            self = .server(response.statusCode, response, data)
        case (_, .some, nil), (.some, nil, nil):
            return nil
        default:
            self = .unhandled(data: data, response: response, error: error)
        }
    }

    public static var unhandled: Standard = .unhandled(data: nil, response: nil, error: nil)
}
