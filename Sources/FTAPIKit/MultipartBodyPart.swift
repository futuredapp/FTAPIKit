import Foundation

/// Structure representing HTTP body part in `multipart/form-data` request.
/// These parts must have valid headers according
/// to [RFC-7578](https://tools.ietf.org/html/rfc7578).
/// Content is converted to `InputStream` at serialization time to limit memory usage.
public struct MultipartBodyPart: Sendable {

    /// Part content, resolved to an `InputStream` at serialization time.
    enum Source: Sendable {
        case data(Data)
        case file(URL)
        case stream(@Sendable () throws -> InputStream)
    }

    let headers: [String: String]
    let source: Source

    /// Creates a new instance with custom headers and a stream factory as body.
    ///
    /// - Parameters:
    ///   - headers: HTTP headers specific for the part, these are not validated locally and must be correct according to [RFC-7578](https://tools.ietf.org/html/rfc7578).
    ///   - makeInputStream: Closure returning a fresh byte stream, called on every serialization.
    public init(headers: [String: String], makeInputStream: @escaping @Sendable () throws -> InputStream) {
        self.headers = headers
        self.source = .stream(makeInputStream)
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
        self.source = .data(data)
    }

    /// Creates a new instance with custom headers and a local file as body.
    ///
    /// - Parameters:
    ///   - headers: HTTP headers specific for the part, these are not validated locally and must be correct according to [RFC-7578](https://tools.ietf.org/html/rfc7578).
    ///   - fileURL: URL to a local file, validated when the multipart body is serialized.
    public init(headers: [String: String], fileURL: URL) {
        self.headers = headers
        self.source = .file(fileURL)
    }

    /// Creates a new instance with file URL used to be converted to body.
    ///
    /// - Parameters:
    ///   - name: Name of the parameter used in `Content-Disposition` header.
    ///   - url: URL to a local file, validated when the multipart body is serialized.
    public init(name: String, url: URL) {
        self.headers = [
            "Content-Type": url.mimeType,
            "Content-Disposition": "form-data; name=\(name); filename=\"\(url.lastPathComponent)\""
        ]
        self.source = .file(url)
    }

    /// Opens a stream over the part's content, called when the multipart body is serialized.
    /// - Throws: An error from the stream factory; file errors surface after the stream is opened.
    func openInputStream() throws -> InputStream {
        switch source {
        case let .data(data):
            return InputStream(data: data)
        case let .file(url):
            guard let inputStream = InputStream(url: url) else {
                throw URLError(.cannotOpenFile, userInfo: ["url": url])
            }
            return inputStream
        case let .stream(makeInputStream):
            return try makeInputStream()
        }
    }
}
