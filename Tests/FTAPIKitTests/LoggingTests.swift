import Foundation
import XCTest
@testable import FTAPIKit

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class LoggingTests: XCTestCase {
    
    func testDefaultLoggerInitialization() {
        let logger = DefaultLogger()
        XCTAssertNotNil(logger)
    }
    
    func testDefaultLoggerWithCustomConfiguration() {
        let configuration = LoggerConfiguration(
            subsystem: "com.test.networking",
            category: "test",
            privacy: .sensitive
        )
        let logger = DefaultLogger(configuration: configuration)
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
    
    
    func testAnalyticsConfiguration() {
        let analyticsConfig = AnalyticsConfiguration(privacy: .sensitive)
        
        let testEntry = AnalyticEntry(
            type: .request,
            method: "POST",
            url: "https://api.example.com/test?token=secret123",
            headers: ["Authorization": "Bearer token123"],
            body: "{\"password\": \"secret\"}".data(using: .utf8)!
        )
        
        let maskedEntry = analyticsConfig.maskAnalyticEntry(testEntry)
        XCTAssertEqual(maskedEntry.type, .request)
        XCTAssertEqual(maskedEntry.method, "POST")
        // Should be masked due to .sensitive privacy
        XCTAssertEqual(maskedEntry.url, "https://api.example.com/test")
        XCTAssertEqual(maskedEntry.headers?["Authorization"], "***")
    }
    
    func testAnalyticsConfigurationCustomSensitive() {
        let customSensitiveHeaders = Set(["custom-auth", "x-custom-token"])
        let customSensitiveQueries = Set(["custom_token", "api_secret"])
        let customSensitiveBodyParams = Set(["custom_password", "secret_key"])
        
        let analyticsConfig = AnalyticsConfiguration(
            privacy: .auto,
            sensitiveHeaders: customSensitiveHeaders,
            sensitiveUrlQueries: customSensitiveQueries,
            sensitiveBodyParams: customSensitiveBodyParams
        )
        
        let testEntry = AnalyticEntry(
            type: .request,
            method: "POST",
            url: "https://api.example.com/test?custom_token=secret123&public_param=value",
            headers: ["custom-auth": "Bearer token123", "Content-Type": "application/json"],
            body: "{\"custom_password\": \"secret\", \"public_field\": \"value\"}".data(using: .utf8)!
        )
        
        let maskedEntry = analyticsConfig.maskAnalyticEntry(testEntry)
        XCTAssertEqual(maskedEntry.type, .request)
        XCTAssertEqual(maskedEntry.method, "POST")
        // Should mask only custom sensitive values in .auto mode
        XCTAssertEqual(maskedEntry.url, "https://api.example.com/test?custom_token=***&public_param=value")
        XCTAssertEqual(maskedEntry.headers?["custom-auth"], "***")
        XCTAssertEqual(maskedEntry.headers?["Content-Type"], "application/json")
    }
    
    
    
    
    func testLogRequest() {
        let logger = DefaultLogger()
        let headers = ["Authorization": "Bearer token123", "Content-Type": "application/json"]
        let body = "{\"test\": \"data\"}".data(using: .utf8)!
        let logEntry = LogEntry(
            type: .request,
            method: "POST",
            url: "https://api.example.com/test",
            headers: headers,
            body: body,
            requestId: "test-request-id"
        )
        
        // This should not crash
        logger.log(logEntry)
    }
    
    func testLogResponse() {
        let logger = DefaultLogger()
        let headers = ["Content-Type": "application/json"]
        let body = "{\"success\": true}".data(using: .utf8)!
        let logEntry = LogEntry(
            type: .response,
            method: "POST",
            url: "https://api.example.com/test",
            headers: headers,
            body: body,
            statusCode: 200,
            duration: 0.5,
            requestId: "test-request-id"
        )
        
        // This should not crash
        logger.log(logEntry)
    }
    
    func testLogError() {
        let logger = DefaultLogger()
        let logEntry = LogEntry(
            type: .error,
            method: "POST",
            url: "https://api.example.com/test",
            error: "Network error",
            requestId: "test-request-id"
        )
        
        // This should not crash
        logger.log(logEntry)
    }
    
    func testLogErrorWithData() {
        let logger = DefaultLogger()
        let errorData = "{\"error\": \"Invalid JSON\"}".data(using: .utf8)!
        let logEntry = LogEntry(
            type: .error,
            method: "POST",
            url: "https://api.example.com/test",
            body: errorData,
            error: "Decoding error",
            requestId: "test-request-id"
        )
        
        // This should not crash and should include data in the log
        logger.log(logEntry)
    }
    
    func testSensitiveHeadersMasking() {
        let logger = DefaultLogger()
        let headers = [
            "Authorization": "Bearer token123",
            "Content-Type": "application/json",
            "X-API-Key": "secret-key"
        ]
        let logEntry = LogEntry(
            type: .request,
            method: "GET",
            url: "https://api.example.com/test",
            headers: headers,
            requestId: "test-request-id"
        )
        
        // This should not crash and should mask sensitive headers
        logger.log(logEntry)
    }
    
    func testSensitiveBodyMasking() {
        let logger = DefaultLogger()
        let body = "{\"password\": \"secret123\", \"username\": \"user\"}".data(using: .utf8)!
        let logEntry = LogEntry(
            type: .request,
            method: "POST",
            url: "https://api.example.com/test",
            body: body,
            requestId: "test-request-id"
        )
        
        // This should not crash and should mask sensitive fields
        logger.log(logEntry)
    }
    
    func testAnalyticsPrivacyMasking() {
        let originalUrl = "https://api.example.com/users?token=secret123"
        let originalHeaders = ["Authorization": "Bearer token123", "Content-Type": "application/json"]
        let originalBody = "{\"password\": \"secret123\", \"username\": \"user\"}".data(using: .utf8)!
        
        // Create original analytic entry
        let originalEntry = AnalyticEntry(
            type: .request,
            url: originalUrl,
            headers: originalHeaders,
            body: originalBody
        )
        
        // Test with .none privacy - should return original data
        let noneConfig = AnalyticsConfiguration(privacy: .none)
        let noneEntry = noneConfig.maskAnalyticEntry(originalEntry)
        XCTAssertEqual(noneEntry.url, originalUrl)
        XCTAssertEqual(noneEntry.headers, originalHeaders)
        XCTAssertEqual(noneEntry.body, originalBody)
        
        // Test with .sensitive privacy - should mask everything
        let sensitiveConfig = AnalyticsConfiguration(privacy: .sensitive)
        let sensitiveEntry = sensitiveConfig.maskAnalyticEntry(originalEntry)
        XCTAssertEqual(sensitiveEntry.url, "https://api.example.com/users")
        XCTAssertEqual(sensitiveEntry.headers?["Authorization"], "***")
        XCTAssertEqual(sensitiveEntry.headers?["Content-Type"], "***")
        XCTAssertEqual(sensitiveEntry.body, originalBody) // Data is preserved, masking happens during display
    }
    
    func testLogEntryBuildMessage() {
        // Test request message
        let requestEntry = LogEntry(
            type: .request,
            method: "POST",
            url: "https://api.example.com/users",
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
            type: .response,
            method: "POST",
            url: "https://api.example.com/users",
            headers: ["Content-Type": "application/json"],
            body: "{\"id\": 123}".data(using: .utf8)!,
            statusCode: 201,
            duration: 0.5,
            requestId: "abc12345"
        )
        
        let responseMessage = responseEntry.buildMessage(configuration: configuration)
        XCTAssertTrue(responseMessage.contains("[RESPONSE]"))
        XCTAssertTrue(responseMessage.contains("201"))
        XCTAssertTrue(responseMessage.contains("500.00ms"))
        
        // Test error message
        let errorEntry = LogEntry(
            type: .error,
            method: "POST",
            url: "https://api.example.com/users",
            body: "{\"error\": \"Connection failed\"}".data(using: .utf8)!,
            error: "Network error",
            requestId: "abc12345"
        )
        
        let errorMessage = errorEntry.buildMessage(configuration: configuration)
        XCTAssertTrue(errorMessage.contains("[ERROR]"))
        XCTAssertTrue(errorMessage.contains("ERROR: Network error"))
        XCTAssertTrue(errorMessage.contains("Data:"))
    }
}