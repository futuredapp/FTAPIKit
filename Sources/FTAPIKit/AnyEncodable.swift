
struct AnyEncodable: Encodable {
    private let anyEncode: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        anyEncode = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try anyEncode(encoder)
    }
}
