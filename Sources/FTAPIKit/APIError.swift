import Foundation

#if os(Linux)
import FoundationNetworking 
#endif

public protocol APIError: Error {
    typealias Standard = APIErrorStandard

    init?(data: Data?, response: URLResponse?, error: Error?, decoding: Decoding)

    static var unhandled: Self { get }
}
