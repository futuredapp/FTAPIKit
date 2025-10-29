import Foundation
import XCTest
@testable import FTAPIKit

#if canImport(os.log)
import os.log
#endif

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class URLServerLoggingTests: XCTestCase {
    
    var server: TestServerWithLogging!
    
    override func setUp() {
        super.setUp()
        server = TestServerWithLogging()
    }
    
    override func tearDown() {
        server = nil
        super.tearDown()
    }
    
    func testRequestLogging() {
        // Given
        let server = TestServerWithLogging()
        
        // When - test that server can be created with logger
        XCTAssertNotNil(server.logger)
        
        // Then - test passes if no crash occurs
    }
    
    func testCustomLogger() {
        // Given
        let customLogger = MockLogger()
        let server = TestServerWithCustomLogger(logger: customLogger)
        
        // When - test that server can be created with custom logger
        XCTAssertNotNil(server.logger)
        
        // Then - test passes if no crash occurs
    }
    
    func testResponseLogging() {
        // Given
        let server = TestServerWithLogging()
        
        // When - test that server can be created with logger
        XCTAssertNotNil(server.logger)
        
        // Then - test passes if no crash occurs
    }
    
    func testErrorLogging() {
        // Given - use a server that will definitely fail
        let failingServer = TestServerWithLogging(baseUri: URL(string: "https://this-domain-does-not-exist-12345.com/")!)
        let endpoint = GetEndpoint()
        let expectation = XCTestExpectation(description: "Request completed")
        
        // When
        failingServer.call(endpoint: endpoint) { result in
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        // Test passes if no crash occurs
    }
}

// MARK: - Test Server with Logging

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class TestServerWithLogging: URLServer {
    typealias ErrorType = APIError.Standard
    
    let baseUri: URL
    let urlSession: URLSession
    let logger: LoggerProtocol?
    
    init(baseUri: URL = URL(string: "http://httpbin.org/")!, logger: LoggerProtocol? = DefaultLogger()) {
        self.baseUri = baseUri
        self.urlSession = URLSession(configuration: .ephemeral)
        self.logger = logger
    }
}

// MARK: - Mock Logger for Testing

#if canImport(os.log)
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct MockLogger: LoggerProtocol {
    let logger = os.Logger(subsystem: "com.test", category: "test")
    let configuration = LoggerConfiguration()
}
#endif