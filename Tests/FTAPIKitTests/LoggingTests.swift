import Foundation
import XCTest
@testable import FTAPIKit

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class LoggingTests: XCTestCase {
    
    func testNetworkLoggerInitialization() {
        let logger = NetworkLogger()
        XCTAssertNotNil(logger)
    }
    
    func testNetworkLoggerWithCustomConfiguration() {
        let configuration = LoggerConfiguration(
            subsystem: "com.test.networking",
            category: "test",
            privacy: .sensitive
        )
        let logger = NetworkLogger(configuration: configuration)
        XCTAssertNotNil(logger)
    }
    
    func testLoggerConfigurationDataDecoder() {
        let jsonData = """
        {"name": "test", "value": 123}
        """.data(using: .utf8)!
        
        let prettyJSON = LoggerConfiguration.defaultDataDecoder(jsonData)
        XCTAssertNotNil(prettyJSON)
        XCTAssertTrue(prettyJSON!.contains("\n")) // Should be pretty printed
        
        let utf8Data = "simple text".data(using: .utf8)!
        let utf8Result = LoggerConfiguration.utf8DataDecoder(utf8Data)
        XCTAssertEqual(utf8Result, "simple text")
        
        let sizeResult = LoggerConfiguration.sizeOnlyDataDecoder(utf8Data)
        XCTAssertEqual(sizeResult, "<11 bytes>")
    }
    
    func testLogRequest() {
        let logger = NetworkLogger()
        let headers = ["Authorization": "Bearer token123", "Content-Type": "application/json"]
        let body = "{\"test\": \"data\"}".data(using: .utf8)
        
        // This should not crash
        logger.logRequest(
            method: "POST",
            url: "https://api.example.com/test",
            headers: headers,
            body: body,
            requestId: "test-request-id"
        )
    }
    
    func testLogResponse() {
        let logger = NetworkLogger()
        let headers = ["Content-Type": "application/json"]
        let body = "{\"success\": true}".data(using: .utf8)
        
        // This should not crash
        logger.logResponse(
            method: "POST",
            url: "https://api.example.com/test",
            statusCode: 200,
            headers: headers,
            body: body,
            duration: 0.5,
            requestId: "test-request-id"
        )
    }
    
    func testLogError() {
        let logger = NetworkLogger()
        
        // This should not crash
        logger.logError(
            method: "POST",
            url: "https://api.example.com/test",
            error: "Network error",
            requestId: "test-request-id"
        )
    }
    
    func testLogErrorWithData() {
        let logger = NetworkLogger()
        let errorData = "{\"error\": \"Invalid JSON\"}".data(using: .utf8)
        
        // This should not crash and should include data in the log
        logger.logError(
            method: "POST",
            url: "https://api.example.com/test",
            error: "Decoding error",
            data: errorData,
            requestId: "test-request-id"
        )
    }
    
    func testSensitiveHeadersMasking() {
        let logger = NetworkLogger()
        let headers = [
            "Authorization": "Bearer token123",
            "Content-Type": "application/json",
            "X-API-Key": "secret-key"
        ]
        
        // This should not crash and should mask sensitive headers
        logger.logRequest(
            method: "GET",
            url: "https://api.example.com/test",
            headers: headers,
            requestId: "test-request-id"
        )
    }
    
    func testSensitiveBodyMasking() {
        let logger = NetworkLogger()
        let body = "{\"password\": \"secret123\", \"username\": \"user\"}".data(using: .utf8)
        
        // This should not crash and should mask sensitive fields
        logger.logRequest(
            method: "POST",
            url: "https://api.example.com/test",
            body: body,
            requestId: "test-request-id"
        )
    }
    
    func testPrivacyAwareLogEntry() {
        let originalUrl = "https://api.example.com/users?token=secret123"
        let originalHeaders = ["Authorization": "Bearer token123", "Content-Type": "application/json"]
        let originalBody = "{\"password\": \"secret123\", \"username\": \"user\"}"
        
        // Create original log entry
        let originalEntry = LogEntry(
            type: .request,
            url: originalUrl,
            headers: originalHeaders,
            body: originalBody
        )
        
        // Test with .none privacy - should return original data
        let noneEntry = originalEntry.withPrivacy(.none)
        XCTAssertEqual(noneEntry.url, originalUrl)
        XCTAssertEqual(noneEntry.headers, originalHeaders)
        XCTAssertEqual(noneEntry.body, originalBody)
        
        // Test with .sensitive privacy - should mask everything
        let sensitiveEntry = originalEntry.withPrivacy(.sensitive)
        XCTAssertEqual(sensitiveEntry.url, "https://api.example.com/users")
        XCTAssertEqual(sensitiveEntry.headers?["Authorization"], "***")
        XCTAssertEqual(sensitiveEntry.headers?["Content-Type"], "***")
        XCTAssertEqual(sensitiveEntry.body, "***")
    }
    
    func testLogEntryBuildMessage() {
        // Test request message
        let requestEntry = LogEntry(
            type: .request,
            method: "POST",
            url: "https://api.example.com/users",
            headers: ["Content-Type": "application/json"],
            body: "{\"username\": \"test\"}",
            requestId: "abc12345"
        )
        
        let requestMessage = requestEntry.buildMessage()
        XCTAssertTrue(requestMessage.contains("[REQUEST]"))
        XCTAssertTrue(requestMessage.contains("POST"))
        XCTAssertTrue(requestMessage.contains("https://api.example.com/users"))
        XCTAssertTrue(requestMessage.contains("Headers:"))
        XCTAssertTrue(requestMessage.contains("Body:"))
        
        // Test response message
        let responseEntry = LogEntry(
            type: .response,
            method: "POST",
            url: "https://api.example.com/users",
            headers: ["Content-Type": "application/json"],
            body: "{\"id\": 123}",
            statusCode: 201,
            duration: 0.5,
            requestId: "abc12345"
        )
        
        let responseMessage = responseEntry.buildMessage()
        XCTAssertTrue(responseMessage.contains("[RESPONSE]"))
        XCTAssertTrue(responseMessage.contains("201"))
        XCTAssertTrue(responseMessage.contains("500.00ms"))
        
        // Test error message
        let errorEntry = LogEntry(
            type: .error,
            method: "POST",
            url: "https://api.example.com/users",
            body: "{\"error\": \"Connection failed\"}",
            error: "Network error",
            requestId: "abc12345"
        )
        
        let errorMessage = errorEntry.buildMessage()
        XCTAssertTrue(errorMessage.contains("[ERROR]"))
        XCTAssertTrue(errorMessage.contains("ERROR: Network error"))
        XCTAssertTrue(errorMessage.contains("Data:"))
    }
}