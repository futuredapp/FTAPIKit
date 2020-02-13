import Foundation

struct User: Codable, Equatable {
    let uuid: UUID
    let name: String
    let age: UInt
}

struct File {
    let url: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(UUID()).txt")
    let data = Data(repeating: UInt8(ascii: "a"), count: 1024 * 1024)
    let headers: [String: String] = [
        "Content-Disposition": "form-data; name=jpegFile",
        "Content-Type": "image/jpeg"
    ]

    func write() throws {
        try data.write(to: url)
    }
}
