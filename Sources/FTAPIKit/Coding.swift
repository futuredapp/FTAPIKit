import Foundation

#if os(Linux)
import FoundationNetworking
#endif

/// `Encoding` represents Swift encoders and provides network-specific features, such as configuring
/// the request with correct headers.
public protocol Encoding {

    /// Encodes the argument
    func encode<T: Encodable>(_ object: T) throws -> Data
}

/// Protocol which enables use of any decoder using type-erasure.
public protocol Decoding {
    func decode<T: Decodable>(data: Data) throws -> T
}

/// Protocol extending encoding with ability to configure `URLRequest`. Used when encoding endpoints in ``URLServer`` calls.
public protocol URLRequestEncoding: Encoding {
    /// Allows modification of `URLRequest`. Enables things like adding `Content-Type` header etc.
    /// - Parameter request: Request which can be modified.
    func configure(request: inout URLRequest) throws
}

/// Type-erased JSON encoder for use with types conforming to ``Server`` protocol.
public struct JSONEncoding: URLRequestEncoding {
    private let encoder: JSONEncoder

    public init(encoder: JSONEncoder = .init()) {
        self.encoder = encoder
    }

    /// Creates new encoder with ability to configure `JSONEncoder` in a compact manner
    /// using a closure.
    ///
    /// - Parameter configure: Function with custom configuration of the encoder
    public init(configure: (_ encoder: JSONEncoder) -> Void) {
        let encoder = JSONEncoder()
        configure(encoder)
        self.encoder = encoder
    }

    public func encode<T: Encodable>(_ object: T) throws -> Data {
        try encoder.encode(object)
    }

    public func configure(request: inout URLRequest) throws {
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    }
}

/// Type-erased JSON decoder for use with types conforming to ``Server`` protocol.
public struct JSONDecoding: Decoding {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }

    /// Creates new decoder with ability to configure `JSONDecoder` in a compact manner
    /// using a closure.
    ///
    /// - Parameter configure: Function with custom configuration of the decoder
    public init(configure: (_ decoder: JSONDecoder) -> Void) {
        let decoder = JSONDecoder()
        configure(decoder)
        self.decoder = decoder
    }

    public func decode<T: Decodable>(data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
