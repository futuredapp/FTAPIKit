import Foundation

public protocol APIError: Error {
    init?(data: Data?, response: URLResponse?, error: Error?, decoder: JSONDecoder)
}

/// Standard API error returned in `APIResult` when no custom error
/// was parsed in the `APIAdapter` first and the response from server
/// was invalid.
public enum StandardAPIError: APIError {
    /// Error raised by NSURLSession corresponding to NSURLErrorCancelled at
    /// domain NSURLErrorDomain.
    case cancelled
    /// Connection error when no response and data was received.
    case connection(Error)
    /// Status code error when the response status code
    /// is larger or equal to 500 and less than 600.
    case server(Int, Data?)
    /// Status code error when the response status code
    /// is larger or equal to 400 and less than 500.
    case client(Int, Data?)
    /// Multipart body part error, when the stream for the part
    /// or the temporary request body stream cannot be opened.
    case multipartStreamCannotBeOpened

    public init?(data: Data?, response: URLResponse?, error: Error?, decoder: JSONDecoder) {
        switch (data, response as? HTTPURLResponse, error) {
        case let (_, _, error as NSError) where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled:
            self = .cancelled
        case let (_, _, error?):
            self = .connection(error)
        case let (data, response?, nil) where 400..<500 ~= response.statusCode:
            self = .client(response.statusCode, data)
        case let (data, response?, nil) where 500..<600 ~= response.statusCode:
            self = .server(response.statusCode, data)
        case (_, .some, nil), (.some, nil, nil):
            return nil
        case (nil, nil, nil):
            fatalError("No response, data or error was returned from URLSession")
        }
    }
}
