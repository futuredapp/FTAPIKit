import XCTest
import Combine

/// There is a guard in each test to check whether Combine is available.
/// If the whole class is marked with `@available` we get segfaults,
/// because the test runner is still trying to execute unavailable test.
/// Last Xcode version where this was checked is 11.5.
final class CombineTests: XCTestCase {
    private let timeout: TimeInterval = 30.0
    private var cancellable: AnyObject?

    override func tearDown() {
        super.tearDown()
        cancellable = nil
    }

    func testEmptyResult() {
        guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else {
            return
        }

        let server = HTTPBinServer()
        let endpoint = NoContentEndpoint()
        let expectation = self.expectation(description: "Result")

        cancellable = server.publisher(endpoint: endpoint)
            .assertNoFailure()
            .sink { expectation.fulfill() }

        wait(for: [expectation], timeout: timeout)
    }

    func testDataPublisher() {
        guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else {
            return
        }

        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        let expectation = self.expectation(description: "Result")

        cancellable = server.publisher(data: endpoint)
            .assertNoFailure()
            .sink { data in
                XCTAssert(!data.isEmpty)
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: timeout)
    }

    func testValidJSONResponse() {
        guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else {
            return
        }

        let server = HTTPBinServer()
        let endpoint = JSONResponseEndpoint()
        let expectation = self.expectation(description: "Result")

        cancellable = server.publisher(data: endpoint)
            .assertNoFailure()
            .sink { _ in
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: timeout)
    }

    func testClientError() {
        guard #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) else {
            return
        }

        let server = HTTPBinServer()
        let endpoint = NotFoundEndpoint()
        let expectation = self.expectation(description: "Result")

        cancellable = server.publisher(data: endpoint)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(.client):
                    XCTAssert(true)
                default:
                    XCTFail("404 endpoint must return client error")
                }
                expectation.fulfill()
            }, receiveValue: { _ in
                XCTFail("404 endpoint must return error")
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: timeout)
    }
}
