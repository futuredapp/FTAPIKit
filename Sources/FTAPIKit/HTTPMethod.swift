/// HTTP method enum with all commonly used verbs.
public enum HTTPMethod: String, CustomStringConvertible {
    /// `OPTIONS` HTTP method
    case options
    /// `GET` HTTP method
    case get
    /// `HEAD` HTTP method
    case head
    /// `POST` HTTP method
    case post
    /// `PUT` HTTP method
    case put
    /// `PATCH` HTTP method
    case patch
    /// `DELETE` HTTP method
    case delete
    /// `TRACE` HTTP method
    case trace
    /// `CONNECT` HTTP method
    case connect

    /// Uppercased HTTP method, used for sending requests.
    public var description: String {
        rawValue.uppercased()
    }
}
