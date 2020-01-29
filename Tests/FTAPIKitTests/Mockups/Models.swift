import Foundation

struct User: Codable, Equatable {
    let uuid: UUID
    let name: String
    let age: UInt
}
