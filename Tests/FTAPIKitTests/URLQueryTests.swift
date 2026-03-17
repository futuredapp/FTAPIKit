import Foundation
import Testing

@testable import FTAPIKit

@Suite
struct URLQueryTests {

    @Test
    func spaceEncoding() {
        let query: URLQuery = [
            "q": "some string"
        ]
        #expect(query.percentEncoded == "q=some%20string")
    }

    @Test
    func delimitersEncoding() {
        let query: URLQuery = [
            "array[]": "a",
            "array[]": "b"
        ]
        #expect(query.percentEncoded == "array%5B%5D=a&array%5B%5D=b")
    }

    @Test
    func queryAppending() {
        var url = URL(string: "http://httpbin.org/get")!
        url.appendQuery(["a": "a"])
        #expect(url.absoluteString == "http://httpbin.org/get?a=a")
    }

    @Test
    func repeatedQueryAppending() {
        var url = URL(string: "http://httpbin.org/get")!
        url.appendQuery(["a": "a"])
        url.appendQuery(["b": "b"])
        #expect(url.absoluteString == "http://httpbin.org/get?a=a&b=b")
    }

    @Test
    func emptyQueryReturnsNil() {
        let query = URLQuery()
        #expect(query.percentEncoded == nil)
    }

    @Test
    func emptyQueryItemValues() {
        let query = URLQuery(items: [
            URLQueryItem(name: "a", value: nil),
            URLQueryItem(name: "b", value: nil)
        ])
        #expect(query.percentEncoded == "a=&b=")
    }
}
