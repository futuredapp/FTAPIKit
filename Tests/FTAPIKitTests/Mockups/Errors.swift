import Foundation
import FTAPIKit

#if os(Linux)
import FoundationNetworking 
#endif

struct ThrowawayAPIError: APIError {
    private init() {}

    init?(data: Data?, response: URLResponse?, error: Error?, decoding: Decoding) {
        self.init()
    }

    static var unhandled = Self()
}
