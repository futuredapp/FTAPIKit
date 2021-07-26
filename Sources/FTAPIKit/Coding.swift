import Foundation

#if os(Linux)
import FoundationNetworking
#endif

/// `Encoding` is not only represents Swift encoders, but also provides network specific feature, such as
/// configuring the request with correct headers.
///
/// - Note: A reference implementation is provided in the form of `JSONEncoding`
public protocol Encoding {

    /// Encodes the argument
    func encode<T: Encodable>(_ object: T) throws -> Data

    /// Sets correct header to the request, such as `Content-Type`
    func configure(request: inout URLRequest) throws
}

/// `Decoding` encapsulates Swift decoders.
public protocol Decoding {
    func decode<T: Decodable>(data: Data) throws -> T
}

/// Reference implementation of `Encoding` using JSON `Foundation.JSONEncoder` under the hood.
public struct JSONEncoding: Encoding {
    private let encoder: JSONEncoder

    public init(encoder: JSONEncoder = .init()) {
        self.encoder = encoder
    }

    /// This initializer is a syntax sugar that provides the the possibility to configure the `JSONEncoder` in
    /// a compact manner.
    /// - Parameter encoder: Encoder which will be used by the instance
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

/// Reference implementation of `Decoding` using JSON `Foundation.Decoding` under the hood.
public struct JSONDecoding: Decoding {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }

    /// This initializer is a syntax sugar that provides the the possibility to configure the `JSONDecoder` in
    /// a compact manner.
    /// - Parameter decoder: Decoder which will be used by the instance
    public init(configure: (_ decoder: JSONDecoder) -> Void) {
        let decoder = JSONDecoder()
        configure(decoder)
        self.decoder = decoder
    }

    public func decode<T: Decodable>(data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
