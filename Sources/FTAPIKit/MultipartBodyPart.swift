import Foundation

/// Structure representing HTTP body part in `multipart/form-data` request.
/// These parts must have valid headers according
/// to [RFC-7578](https://tools.ietf.org/html/rfc7578).
/// Everything passed to it is converted to `InputStream`
/// in order to limit memory usage when sending files to a server.
public struct MultipartBodyPart {
    let headers: [String: String]
    let inputStream: InputStream

    /// Creates a new instance with custom headers and any input stream.
    ///
    /// - Parameters:
    ///   - headers: HTTP headers specific for the part, these are not validated locally and must be correct according to [RFC-7578](https://tools.ietf.org/html/rfc7578).
    ///   - inputStream: Any byte stream.
    public init(headers: [String: String], inputStream: InputStream) {
        self.headers = headers
        self.inputStream = inputStream
    }

    /// Creates a new instance from key-value or HTTP parameter.
    ///
    /// - Parameters:
    ///   - name: Name of the parameter used in `Content-Disposition` header.
    ///   - value: String value of the parameter set as a body.
    public init(name: String, value: String) {
        let headers = [
            "Content-Disposition": "form-data; name=\(name)"
        ]
        self.init(headers: headers, data: Data(value.utf8))
    }

    /// Creates a new instance with custom headers and data as body.
    ///
    /// - Parameters:
    ///   - headers: HTTP headers specific for the part, these are not validated locally and must be correct according to [RFC-7578](https://tools.ietf.org/html/rfc7578).
    ///   - data: Bytes sent as a part body.
    public init(headers: [String: String], data: Data) {
        self.headers = headers
        self.inputStream = InputStream(data: data)
    }

    /// Creates a new instance with file URL used to be converted to body.
    ///
    /// - Parameters:
    ///   - name: Name of the parameter used in `Content-Disposition` header.
    ///   - url: URL to a local file.
    /// - Throws: `URLError` with `cannotOpenFile` code if it was not possible to open the file at the provided URL.
    public init(name: String, url: URL) throws {
        guard let inputStream = InputStream(url: url) else {
            throw URLError(.cannotOpenFile, userInfo: ["url": url])
        }
        self.headers = [
            "Content-Type": url.mimeType,
            "Content-Disposition": "form-data; name=\(name); filename=\"\(url.lastPathComponent)\""
        ]
        self.inputStream = inputStream
    }
}
