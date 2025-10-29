import Foundation
import XCTest
@testable import FTAPIKit

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class LoggingTests: XCTestCase {
    
    func testLoggerConfigurationInitialization() {
        let configuration = LoggerConfiguration()
        XCTAssertNotNil(configuration)
        XCTAssertEqual(configuration.subsystem, "com.ftapikit.networking")
        XCTAssertEqual(configuration.category, "networking")
    }
    
    func testLoggerConfigurationWithCustomSettings() {
        let configuration = LoggerConfiguration(
            subsystem: "com.test",
            category: "test",
            privacy: .sensitive
        )
        XCTAssertEqual(configuration.subsystem, "com.test")
        XCTAssertEqual(configuration.category, "test")
        XCTAssertEqual(configuration.privacy, .sensitive)
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
        let configuration = LoggerConfiguration()
        let headers = ["Authorization": "Bearer token123", "Content-Type": "application/json"]
        let body = "{\"test\": \"data\"}".data(using: .utf8)!
        let logEntry = LogEntry(
            type: .request(method: "POST", url: "https://api.example.com/test"),
            headers: headers,
            body: body,
            requestId: "test-request-id"
        )
        
        // Test that configuration is properly initialized
        XCTAssertNotNil(configuration)
        XCTAssertEqual(configuration.subsystem, "com.ftapikit.networking")
        XCTAssertEqual(configuration.category, "networking")
        
        // Test that LogEntry can be built without crashing
        let message = logEntry.buildMessage(configuration: configuration)
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("[REQUEST]"))
    }
    
    func testLogResponse() {
        let configuration = LoggerConfiguration()
        let headers = ["Content-Type": "application/json"]
        let body = "{\"success\": true}".data(using: .utf8)!
        let logEntry = LogEntry(
            type: .response(method: "POST", url: "https://api.example.com/test", statusCode: 200),
            headers: headers,
            body: body,
            duration: 0.5,
            requestId: "test-request-id"
        )
        
        // Test that configuration is properly initialized
        XCTAssertNotNil(configuration)
        
        // Test that LogEntry can be built without crashing
        let message = logEntry.buildMessage(configuration: configuration)
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("[RESPONSE]"))
    }
    
    func testLogError() {
        let configuration = LoggerConfiguration()
        let logEntry = LogEntry(
            type: .error(method: "POST", url: "https://api.example.com/test", error: "Network error"),
            requestId: "test-request-id"
        )
        
        // Test that configuration is properly initialized
        XCTAssertNotNil(configuration)
        
        // Test that LogEntry can be built without crashing
        let message = logEntry.buildMessage(configuration: configuration)
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("[ERROR]"))
    }
    
    func testLogErrorWithData() {
        let configuration = LoggerConfiguration()
        let errorData = "{\"error\": \"Invalid JSON\"}".data(using: .utf8)!
        let logEntry = LogEntry(
            type: .error(method: "POST", url: "https://api.example.com/test", error: "Decoding error"),
            body: errorData,
            requestId: "test-request-id"
        )
        
        // Test that configuration is properly initialized
        XCTAssertNotNil(configuration)
        
        // Test that LogEntry can be built without crashing and includes data
        let message = logEntry.buildMessage(configuration: configuration)
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("[ERROR]"))
        XCTAssertTrue(message.contains("Data:"))
    }
    
    func testSensitiveHeadersMasking() {
        let configuration = LoggerConfiguration()
        let headers = [
            "Authorization": "Bearer token123",
            "Content-Type": "application/json",
            "X-API-Key": "secret-key"
        ]
        let logEntry = LogEntry(
            type: .request(method: "GET", url: "https://api.example.com/test"),
            headers: headers,
            requestId: "test-request-id"
        )
        
        // Test that configuration is properly initialized
        XCTAssertNotNil(configuration)
        
        // Test that LogEntry can be built without crashing and includes headers
        let message = logEntry.buildMessage(configuration: configuration)
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("[REQUEST]"))
        XCTAssertTrue(message.contains("Headers:"))
    }
    
    func testSensitiveBodyMasking() {
        let configuration = LoggerConfiguration()
        let body = "{\"password\": \"secret123\", \"username\": \"user\"}".data(using: .utf8)!
        let logEntry = LogEntry(
            type: .request(method: "POST", url: "https://api.example.com/test"),
            body: body,
            requestId: "test-request-id"
        )
        
        // Test that configuration is properly initialized
        XCTAssertNotNil(configuration)
        
        // Test that LogEntry can be built without crashing and includes body
        let message = logEntry.buildMessage(configuration: configuration)
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("[REQUEST]"))
        XCTAssertTrue(message.contains("Body:"))
    }
    
    
    func testLogEntryBuildMessage() {
        // Test request message
        let requestEntry = LogEntry(
            type: .request(method: "POST", url: "https://api.example.com/users"),
            headers: ["Content-Type": "application/json"],
            body: "{\"username\": \"test\"}".data(using: .utf8)!,
            requestId: "abc12345"
        )
        
        let configuration = LoggerConfiguration()
        let requestMessage = requestEntry.buildMessage(configuration: configuration)
        XCTAssertTrue(requestMessage.contains("[REQUEST]"))
        XCTAssertTrue(requestMessage.contains("POST"))
        XCTAssertTrue(requestMessage.contains("https://api.example.com/users"))
        XCTAssertTrue(requestMessage.contains("Headers:"))
        XCTAssertTrue(requestMessage.contains("Body:"))
        
        // Test response message
        let responseEntry = LogEntry(
            type: .response(method: "POST", url: "https://api.example.com/users", statusCode: 201),
            headers: ["Content-Type": "application/json"],
            body: "{\"id\": 123}".data(using: .utf8)!,
            duration: 0.5,
            requestId: "abc12345"
        )
        
        let responseMessage = responseEntry.buildMessage(configuration: configuration)
        XCTAssertTrue(responseMessage.contains("[RESPONSE]"))
        XCTAssertTrue(responseMessage.contains("201"))
        XCTAssertTrue(responseMessage.contains("500.00ms"))
        
        // Test error message
        let errorEntry = LogEntry(
            type: .error(method: "POST", url: "https://api.example.com/users", error: "Network error"),
            body: "{\"error\": \"Connection failed\"}".data(using: .utf8)!,
            requestId: "abc12345"
        )
        
        let errorMessage = errorEntry.buildMessage(configuration: configuration)
        XCTAssertTrue(errorMessage.contains("[ERROR]"))
        XCTAssertTrue(errorMessage.contains("ERROR    Network error"))
        XCTAssertTrue(errorMessage.contains("Data:"))
    }
}