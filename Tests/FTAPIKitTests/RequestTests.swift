import FTAPIKit
import XCTest

final class RequestTests: XCTestCase {
    func testURLEncode() {
        let server = HTTPBinServer()
        let endpoint = TestURLQueryEndpoint()
        let request = try? server.buildStandardRequest(endpoint: endpoint)

        XCTAssert(request?.url?.absoluteString == "http://httpbin.org/get?param1=value1&param2=value%202&param3=value%20%60%23~%5E%26*%7B%7D%C2%B0%5E%C2%A7%E2%82%AC%5D%E2%80%93%3E%3C%5B")
    }
}
