
import XCTest
import FTAPIKit
import Combine

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class PublisherTests: XCTestCase {
    private let timeout: TimeInterval = 30.0

    private var cancellable: AnyCancellable?

    override func tearDown() {
        super.tearDown()
        cancellable = nil
    }

    func testGet() {
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        let expectation = self.expectation(description: "Result")
        cancellable = server.publisher(endpoint: endpoint)
            .assertNoFailure()
            .sink { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: timeout)
    }

    func testConnectionError() {
        let server = NonExistingServer()
        let endpoint = NotFoundEndpoint()
        let expectation = self.expectation(description: "Result")
        cancellable = server.publisher(endpoint: endpoint)
            .map { _ in XCTFail() }
            .mapError { error -> APIErrorStandard in
                if case .connection = error {
                    XCTAssertTrue(true)
                } else {
                    XCTFail()
                }
                return error
            }
            .replaceError(with: ())
            .sink { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: timeout)
    }

    func testValidJSONResponse() {
        let server = HTTPBinServer()
        let endpoint = JSONResponseEndpoint()
        let expectation = self.expectation(description: "Result")
        cancellable = server.publisher(response: endpoint)
            .assertNoFailure()
            .sink { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: timeout)
    }
}
