import Foundation

#if os(Linux)
import FoundationNetworking
#endif

/// Standard API error returned when no custom error
/// was parsed and the response from server
/// was invalid.
public enum APIErrorStandard: APIError {
    /// Error returned by URL loading APIs.
    case connection(URLError)
    /// An error that occurs during the encoding of a value.
    case encoding(EncodingError)
    /// An error that occurs during the decoding of a value.
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

    public static let unhandled: Standard = .unhandled(data: nil, response: nil, error: nil)
}
