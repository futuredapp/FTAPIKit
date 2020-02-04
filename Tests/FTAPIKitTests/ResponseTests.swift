import XCTest
import FTAPIKit

final class ResponseTests: XCTestCase {
    private let timeout: TimeInterval = 30.0

    func testGet() {
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        let expectation = self.expectation(description: "Result")
        server.call(endpoint: endpoint) { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testClientError() {
        let server = HTTPBinServer()
        let endpoint = NotFoundEndpoint()
        let expectation = self.expectation(description: "Result")
        server.call(endpoint: endpoint) { result in
            switch result {
            case .success:
                XCTFail("404 endpoint must return error")
            case .failure(.client):
                XCTAssert(true)
            case .failure:
                XCTFail("404 endpoint must return client error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testServerError() {
        let server = HTTPBinServer()
        let endpoint = ServerErrorEndpoint()
        let expectation = self.expectation(description: "Result")
        server.call(endpoint: endpoint) { result in
            switch result {
            case .success:
                XCTFail("500 endpoint must return error")
            case .failure(.server):
                XCTAssert(true)
            case .failure:
                XCTFail("500 endpoint must return server error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testConnectionError() {
        let server = NonExistingServer()
        let endpoint = NotFoundEndpoint()
        let expectation = self.expectation(description: "Result")
        server.call(endpoint: endpoint) { result in
            switch result {
            case .success:
                XCTFail("Non-existing domain must fail")
            case .failure(.connection):
                XCTAssert(true)
            case .failure:
                XCTFail("Non-existing domain must throw connection error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testEmptyResult() {
        let server = HTTPBinServer()
        let endpoint = NoContentEndpoint()
        let expectation = self.expectation(description: "Result")
        server.call(endpoint: endpoint) { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testCustomError() {
        let server = ErrorThrowingServer()
        let endpoint = GetEndpoint()
        let expectation = self.expectation(description: "Result")
        server.call(endpoint: endpoint) { result in
            if case .success = result {
                XCTFail("Custom error must be returned")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testValidJSONResponse() {
        let server = HTTPBinServer()
        let endpoint = JSONResponseEndpoint()
        let expectation = self.expectation(description: "Result")
        server.call(response: endpoint) { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testValidJSONRequestResponse() {
        let server = HTTPBinServer()
        let user = User(uuid: UUID(), name: "Some Name", age: .random(in: 0...120))
        let endpoint = UpdateUserEndpoint(request: user)
        let expectation = self.expectation(description: "Result")
        server.call(response: endpoint) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(user, response.json)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testInvalidJSONRequestResponse() {
        let server = HTTPBinServer()
        let user = User(uuid: UUID(), name: "Some Name", age: .random(in: 0...120))
        let endpoint = FailingUpdateUserEndpoint(request: user)
        let expectation = self.expectation(description: "Result")
        server.call(response: endpoint) { result in
            if case .success = result {
                XCTFail("Received valid value, decoding must fail")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testAuthorization() {
        let server = HTTPBinServer()
        let endpoint = AuthorizedEndpoint()
        let expectation = self.expectation(description: "Result")
        server.call(endpoint: endpoint) { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testMultipartData() {
        let server = HTTPBinServer()
        let file = File()
        try! file.data.write(to: file.url)
        let endpoint = try! TestMultipartEndpoint(file: file)
        let expectation = self.expectation(description: "Result")
        server.call(endpoint: endpoint) { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    static var allTests = [
        ("testGet", testGet),
        ("testClientError", testClientError),
        ("testServerError", testServerError),
        ("testConnectionError", testConnectionError),
        ("testEmptyResult", testEmptyResult),
        ("testCustomError", testCustomError),
        ("testValidJSONResponse", testValidJSONResponse),
        ("testValidJSONRequestResponse", testValidJSONRequestResponse),
        ("testInvalidJSONRequestResponse", testInvalidJSONRequestResponse),
        ("testAuthorization", testAuthorization),
    ]
}
