import Foundation

public protocol Encoding {
    func encode<T: Encodable>(_ object: T) throws -> Data
    func configure(request: inout URLRequest) throws
}

public protocol Decoding {
    func decode<T: Decodable>(data: Data) throws -> T
}

public struct JSONEncoding: Encoding {
    private let encoder: JSONEncoder

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

    public func configure(request: inout URLRequest) throws {
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    }
}


public struct JSONDecoding: Decoding {
    private let decoder: JSONDecoder

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
