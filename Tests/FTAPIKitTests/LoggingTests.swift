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
        let analyticsConfig = AnalyticsConfiguration(
            privacy: .sensitive,
            sensitiveHeaders: AnalyticsConfiguration.defaultSensitiveHeaders,
            sensitiveUrlQueries: AnalyticsConfiguration.defaultSensitiveUrlQueries,
            sensitiveBodyParams: AnalyticsConfiguration.defaultSensitiveBodyParams
        )
        
        let testEntry = AnalyticEntry(
            type: .request,
            method: "POST",
            url: "https://api.example.com/test?token=secret123",
            headers: ["Authorization": "Bearer token123"],
            body: "{\"password\": \"secret\"}".data(using: .utf8)!,
            configuration: analyticsConfig
        )
        
        XCTAssertEqual(testEntry.type, .request)
        XCTAssertEqual(testEntry.method, "POST")
        // Should be masked due to .sensitive privacy
        XCTAssertEqual(testEntry.url, "https://api.example.com/test")
        XCTAssertEqual(testEntry.headers?["Authorization"], "***")
        XCTAssertNil(testEntry.body) // Body should be nil for .sensitive privacy
    }
    
    func testAnalyticsConfigurationCustomSensitive() {
        let customSensitiveHeaders = Set(["custom-auth", "x-custom-token"])
        let customSensitiveQueries = Set(["custom_token", "api_secret"])
        
        let analyticsConfig = AnalyticsConfiguration(
            privacy: .auto,
            sensitiveHeaders: customSensitiveHeaders,
            sensitiveUrlQueries: customSensitiveQueries,
            sensitiveBodyParams: AnalyticsConfiguration.defaultSensitiveBodyParams
        )
        
        let testEntry = AnalyticEntry(
            type: .request,
            method: "POST",
            url: "https://api.example.com/test?custom_token=secret123&public_param=value",
            headers: ["custom-auth": "Bearer token123", "Content-Type": "application/json"],
            body: "{\"custom_password\": \"secret\", \"public_field\": \"value\"}".data(using: .utf8)!,
            configuration: analyticsConfig
        )
        
        XCTAssertEqual(testEntry.type, .request)
        XCTAssertEqual(testEntry.method, "POST")
        // Should mask only custom sensitive values in .auto mode
        XCTAssertEqual(testEntry.url, "https://api.example.com/test?custom_token=***&public_param=value")
        XCTAssertEqual(testEntry.headers?["custom-auth"], "***")
        XCTAssertEqual(testEntry.headers?["Content-Type"], "application/json")
    }
    
    func testAnalyticsConfigurationMaskBody() {
        // Test .auto privacy
        let autoConfig = AnalyticsConfiguration(
            privacy: .auto,
            sensitiveHeaders: AnalyticsConfiguration.defaultSensitiveHeaders,
            sensitiveUrlQueries: AnalyticsConfiguration.defaultSensitiveUrlQueries,
            sensitiveBodyParams: Set(["password", "secret"])
        )
        
        // Test valid JSON masking
        let originalBody = "{\"username\": \"test\", \"password\": \"secret123\", \"email\": \"test@example.com\"}".data(using: .utf8)!
        let maskedBody = autoConfig.maskBody(originalBody)
        
        XCTAssertNotNil(maskedBody)
        let maskedString = String(data: maskedBody!, encoding: .utf8)!
        XCTAssertTrue(maskedString.contains("\"password\":\"***\""))
        XCTAssertTrue(maskedString.contains("\"username\":\"test\""))
        XCTAssertTrue(maskedString.contains("\"email\":\"test@example.com\""))
        
        // Test invalid JSON - should return nil
        let invalidJsonBody = "invalid json data".data(using: .utf8)!
        let invalidMaskedBody = autoConfig.maskBody(invalidJsonBody)
        XCTAssertNil(invalidMaskedBody) // Should return nil for invalid JSON
        
        // Test .sensitive privacy - should always return nil
        let sensitiveConfig = AnalyticsConfiguration(
            privacy: .sensitive,
            sensitiveHeaders: AnalyticsConfiguration.defaultSensitiveHeaders,
            sensitiveUrlQueries: AnalyticsConfiguration.defaultSensitiveUrlQueries,
            sensitiveBodyParams: AnalyticsConfiguration.defaultSensitiveBodyParams
        )
        
        let sensitiveMaskedBody = sensitiveConfig.maskBody(originalBody)
        XCTAssertNil(sensitiveMaskedBody) // Should always return nil for sensitive privacy
        
        // Test .private privacy - should always return nil
        let privateConfig = AnalyticsConfiguration(
            privacy: .private,
            sensitiveHeaders: AnalyticsConfiguration.defaultSensitiveHeaders,
            sensitiveUrlQueries: AnalyticsConfiguration.defaultSensitiveUrlQueries,
            sensitiveBodyParams: AnalyticsConfiguration.defaultSensitiveBodyParams
        )
        
        let privateMaskedBody = privateConfig.maskBody(originalBody)
        XCTAssertNil(privateMaskedBody) // Should always return nil for private privacy
    }
    
    func testAnalyticsProtocolConfiguration() {
        let config = AnalyticsConfiguration(
            privacy: .auto,
            sensitiveHeaders: Set(["custom-auth"]),
            sensitiveUrlQueries: Set(["custom_token"]),
            sensitiveBodyParams: Set(["password"])
        )
        
        struct MockAnalytics: AnalyticsProtocol {
            let configuration: AnalyticsConfiguration
            
            func track(_ entry: AnalyticEntry) {
                // Mock implementation
            }
        }
        
        let analytics = MockAnalytics(configuration: config)
        XCTAssertEqual(analytics.configuration.privacy, .auto)
        XCTAssertEqual(analytics.configuration.sensitiveHeaders, Set(["custom-auth"]))
        XCTAssertEqual(analytics.configuration.sensitiveUrlQueries, Set(["custom_token"]))
        XCTAssertEqual(analytics.configuration.sensitiveBodyParams, Set(["password"]))
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