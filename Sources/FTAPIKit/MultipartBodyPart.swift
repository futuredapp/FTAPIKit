import Foundation

/// Structure representing HTTP body part in `multipart/form-data` request.
/// These parts must have valid headers according
/// to [RFC-7578](https://tools.ietf.org/html/rfc7578).
/// The part stores a description of its content and is converted to `InputStream` at
/// serialization time, in order to limit memory usage when sending files to a server.
public struct MultipartBodyPart: Sendable {

    /// Part content, resolved to an `InputStream` at serialization time.
    enum Source: Sendable {
        case data(Data)
        case file(URL)
        case stream(@Sendable () throws -> InputStream)
    }

    let headers: [String: String]
    let source: Source

    /// Creates a new instance with custom headers and a factory producing the byte stream.
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
    ///   - fileURL: URL to a local file.
    public init(headers: [String: String], fileURL: URL) {
        self.headers = headers
        self.source = .file(fileURL)
    }

    /// Creates a new instance with file URL used to be converted to body.
    ///
    /// - Parameters:
    ///   - name: Name of the parameter used in `Content-Disposition` header.
    ///   - url: URL to a local file.
    /// - Throws: `URLError` with `cannotOpenFile` code if the file at the provided URL is not readable.
    public init(name: String, url: URL) throws {
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw URLError(.cannotOpenFile, userInfo: ["url": url])
        }
        self.headers = [
            "Content-Type": url.mimeType,
            "Content-Disposition": "form-data; name=\(name); filename=\"\(url.lastPathComponent)\""
        ]
        self.source = .file(url)
    }

    /// Opens a stream over the part's content, called when the multipart body is serialized.
    /// - Throws: `URLError` with `cannotOpenFile` code if it was not possible to open the file.
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
