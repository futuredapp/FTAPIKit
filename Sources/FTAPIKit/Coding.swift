import Foundation

public protocol Encoding {
    func encode<T: Encodable>(_ object: T) throws -> Data
}

public protocol Decoding {
    func decode<T: Decodable>(data: Data) throws -> T
}

public struct JSONEncoding: Encoding {
    let encoder: JSONEncoder

    public init(encoder: JSONEncoder = .init()) {
        self.encoder = encoder
    }

    public init(configure: (JSONEncoder) -> Void) {
        let encoder = JSONEncoder()
        configure(encoder)
        self.encoder = encoder
    }

    public func encode<T: Encodable>(_ object: T) throws -> Data {
        try encoder.encode(object)
    }
}


public struct JSONDecoding: Decoding {
    let decoder: JSONDecoder

    public init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }

    public init(configure: (JSONDecoder) -> Void) {
        let decoder = JSONDecoder()
        configure(decoder)
        self.decoder = decoder
    }

    public func decode<T: Decodable>(data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
