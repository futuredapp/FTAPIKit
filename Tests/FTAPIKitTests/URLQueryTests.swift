@testable import FTAPIKit
import XCTest

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

    func testQueryAppending() {
        var url = URL(string: "http://httpbin.org/get")!
        url.appendQuery(["a": "a"])
        XCTAssertEqual(url.absoluteString, "http://httpbin.org/get?a=a")
    }

    func testRepeatedQueryAppending() {
        var url = URL(string: "http://httpbin.org/get")!
        url.appendQuery(["a": "a"])
        url.appendQuery(["b": "b"])
        XCTAssertEqual(url.absoluteString, "http://httpbin.org/get?a=a&b=b")
    }

    func testEmptyQueryItemValues() {
        let query = URLQuery(items: [
            URLQueryItem(name: "a", value: nil),
            URLQueryItem(name: "b", value: nil)
        ])
        XCTAssertEqual(query.percentEncoded, "a=&b=")
    }

    static let allTests = [
        ("testSpaceEncoding", testSpaceEncoding),
        ("testDelimitersEncoding", testDelimitersEncoding),
        ("testQueryAppending", testQueryAppending),
        ("testRepeatedQueryAppending", testRepeatedQueryAppending),
        ("testEmptyQueryItemValues", testEmptyQueryItemValues)
    ]
}
