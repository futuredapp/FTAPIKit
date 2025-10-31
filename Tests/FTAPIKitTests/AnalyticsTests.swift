import Foundation
import XCTest
@testable import FTAPIKit

class AnalyticsTests: XCTestCase {

    func testSensitivePrivacy() {
        let config = AnalyticsConfiguration(
            privacy: .sensitive,
            unmaskedHeaders: ["public_header"],
            unmaskedUrlQueries: ["public_query"],
            unmaskedBodyParams: ["public_param"]
        )

        let entry = AnalyticEntry(
            type: .request(method: "GET", url: "https://example.com/path?secret_query=1&public_query=2"),
            headers: ["secret_header": "foo", "public_header": "bar"],
            body: "{\"secret_param\": \"foo\", \"public_param\": \"bar\"}".data(using: .utf8),
            configuration: config
        )

        XCTAssertEqual(entry.url, "https://example.com/path")
        XCTAssertEqual(entry.headers?["secret_header"], "***")
        XCTAssertEqual(entry.headers?["public_header"], "***") // Ignored
        XCTAssertNil(entry.body)
    }

    func testPrivatePrivacy() {
        let config = AnalyticsConfiguration(
            privacy: .private,
            unmaskedHeaders: ["public_header"],
            unmaskedUrlQueries: ["public_query"],
            unmaskedBodyParams: ["public_param"]
        )

        let entry = AnalyticEntry(
            type: .request(method: "GET", url: "https://example.com/path?secret_query=1&public_query=2"),
            headers: ["secret_header": "foo", "public_header": "bar"],
            body: "{\"secret_param\": \"foo\", \"public_param\": \"bar\"}".data(using: .utf8),
            configuration: config
        )

        XCTAssertTrue(entry.url.contains("secret_query=***"))
        XCTAssertTrue(entry.url.contains("public_query=2"))
        XCTAssertEqual(entry.headers?["secret_header"], "***")
        XCTAssertEqual(entry.headers?["public_header"], "bar")

        let bodyString = entry.body.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertTrue(bodyString?.contains("\"secret_param\":\"***\"") ?? false)
        XCTAssertTrue(bodyString?.contains("\"public_param\":\"bar\"") ?? false)
    }

    func testNonePrivacy() {
        let config = AnalyticsConfiguration(
            privacy: .none
        )

        let url = "https://example.com/path?secret_query=1&public_query=2"
        let headers = ["secret_header": "foo", "public_header": "bar"]
        let body = "{\"secret_param\": \"foo\", \"public_param\": \"bar\"}".data(using: .utf8)

        let entry = AnalyticEntry(
            type: .request(method: "GET", url: url),
            headers: headers,
            body: body,
            configuration: config
        )

        XCTAssertEqual(entry.url, url)
        XCTAssertEqual(entry.headers, headers)
        XCTAssertEqual(entry.body, body)
    }

    func testRecursiveBodyMasking() {
        let config = AnalyticsConfiguration(
            privacy: .private,
            unmaskedBodyParams: ["public_param", "public_nested_object"]
        )

        let json = """
        {
            \"secret_param\": \"foo\",
            \"public_param\": \"bar\",
            \"nested_object\": {
                \"secret_nested_param\": \"baz\",
                \"public_nested_object\": {
                    \"another_secret\": \"qux\"
                }
            },
            \"array_of_objects\": [
                { \"secret_in_array\": \"foo\" },
                { \"public_param\": \"visible\" }
            ]
        }
        """.data(using: .utf8)

        let entry = AnalyticEntry(
            type: .request(method: "GET", url: "https://example.com"),
            body: json,
            configuration: config
        )

        let body = entry.body!
        let maskedJSON = try! JSONSerialization.jsonObject(with: body, options: []) as! [String: Any]

        XCTAssertEqual(maskedJSON["secret_param"] as? String, "***")
        XCTAssertEqual(maskedJSON["public_param"] as? String, "bar")

        let nestedObject = maskedJSON["nested_object"] as! [String: Any]
        XCTAssertEqual(nestedObject["secret_nested_param"] as? String, "***")
        XCTAssertNotNil(nestedObject["public_nested_object"])

        let publicNestedObject = nestedObject["public_nested_object"] as! [String: Any]
        XCTAssertEqual(publicNestedObject["another_secret"] as? String, "qux")

        let array = maskedJSON["array_of_objects"] as! [Any]
        let firstObjectInArray = array[0] as! [String: Any]
        XCTAssertEqual(firstObjectInArray["secret_in_array"] as? String, "***")
        let secondObjectInArray = array[1] as! [String: Any]
        XCTAssertEqual(secondObjectInArray["public_param"] as? String, "visible")
    }
}