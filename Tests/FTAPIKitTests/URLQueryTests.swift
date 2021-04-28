import XCTest
@testable import FTAPIKit

final class URLQueryTests: XCTestCase {
    func testSpaceEncoding() {
        let query: URLQuery = [
            "q": "some string"
        ]
        XCTAssertEqual(query.percentEncoded, "q=some%20string")
    }
    
    func testDelimitersEncoding() {
        let query: URLQuery = [
            "array[]": "a",
            "array[]": "b"
        ]
        XCTAssertEqual(query.percentEncoded, "array%5B%5D=a&array%5B%5D=b")
    }
    
    func testQueryAppending() throws {
        var url = URL(string: "http://httpbin.org/get")!
        url.appendQuery(["a": "a"])
        XCTAssertEqual(url.absoluteString, "http://httpbin.org/get?a=a")
    }
    
    func testRepeatedQueryAppending() throws {
        var url = URL(string: "http://httpbin.org/get")!
        url.appendQuery(["a": "a"])
        url.appendQuery(["b": "b"])
        XCTAssertEqual(url.absoluteString, "http://httpbin.org/get?a=a&b=b")
    }
}
