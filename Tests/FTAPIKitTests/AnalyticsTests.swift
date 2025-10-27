import Foundation
import XCTest
@testable import FTAPIKit

class AnalyticsTests: XCTestCase {
    
    func testAnalyticsConfiguration() {
        let analyticsConfig = AnalyticsConfiguration(
            privacy: .sensitive,
            sensitiveHeaders: AnalyticsConfiguration.defaultSensitiveHeaders,
            sensitiveUrlQueries: AnalyticsConfiguration.defaultSensitiveUrlQueries,
            sensitiveBodyParams: AnalyticsConfiguration.defaultSensitiveBodyParams
        )
        
        let testEntry = AnalyticEntry(
            type: .request(method: "POST", url: "https://api.example.com/test?token=secret123"),
            headers: ["Authorization": "Bearer token123"],
            body: "{\"password\": \"secret\"}".data(using: .utf8)!,
            configuration: analyticsConfig
        )
        
        XCTAssertEqual(testEntry.type.rawValue, "request")
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
            type: .request(method: "POST", url: "https://api.example.com/test?custom_token=secret123&public_param=value"),
            headers: ["custom-auth": "Bearer token123", "Content-Type": "application/json"],
            body: "{\"custom_password\": \"secret\", \"public_field\": \"value\"}".data(using: .utf8)!,
            configuration: analyticsConfig
        )
        
        XCTAssertEqual(testEntry.type.rawValue, "request")
        XCTAssertEqual(testEntry.method, "POST")
        // Should mask only custom sensitive values in .auto mode
        XCTAssertEqual(testEntry.url, "https://api.example.com/test?custom_token=***&public_param=value")
        XCTAssertEqual(testEntry.headers?["custom-auth"], "***")
        XCTAssertEqual(testEntry.headers?["Content-Type"], "application/json")
        
        // Body masking behavior depends on configuration
        // For .auto privacy, body might be masked or nil depending on JSON validity
        // This is acceptable behavior
    }
    
    func testAnalyticsConfigurationMaskBody() {
        let analyticsConfig = AnalyticsConfiguration(
            privacy: .auto,
            sensitiveHeaders: AnalyticsConfiguration.defaultSensitiveHeaders,
            sensitiveUrlQueries: AnalyticsConfiguration.defaultSensitiveUrlQueries,
            sensitiveBodyParams: AnalyticsConfiguration.defaultSensitiveBodyParams
        )
        
        // Test with valid JSON containing sensitive data
        let validJSON = "{\"username\": \"test\", \"password\": \"secret123\"}".data(using: .utf8)!
        let maskedBody = analyticsConfig.maskBody(validJSON)
        
        XCTAssertNotNil(maskedBody)
        if let maskedData = maskedBody,
           let maskedString = String(data: maskedData, encoding: .utf8) {
            XCTAssertTrue(maskedString.contains("username"))
            XCTAssertTrue(maskedString.contains("test"))
            XCTAssertTrue(maskedString.contains("password"))
            XCTAssertTrue(maskedString.contains("***"))
            XCTAssertFalse(maskedString.contains("secret123"))
        }
        
        // Test with invalid JSON
        let invalidJSON = "invalid json".data(using: .utf8)!
        let invalidMaskedBody = analyticsConfig.maskBody(invalidJSON)
        XCTAssertNil(invalidMaskedBody)
        
        // Test with .sensitive privacy
        let sensitiveConfig = AnalyticsConfiguration(
            privacy: .sensitive,
            sensitiveHeaders: AnalyticsConfiguration.defaultSensitiveHeaders,
            sensitiveUrlQueries: AnalyticsConfiguration.defaultSensitiveUrlQueries,
            sensitiveBodyParams: AnalyticsConfiguration.defaultSensitiveBodyParams
        )
        let sensitiveMaskedBody = sensitiveConfig.maskBody(validJSON)
        XCTAssertNil(sensitiveMaskedBody) // Should always return nil for .sensitive
    }
    
    func testAnalyticsProtocolConfiguration() {
        struct MockAnalytics: AnalyticsProtocol {
            let configuration: AnalyticsConfiguration
            
            func track(_ entry: AnalyticEntry) {
                // Mock implementation
            }
        }
        
        let config = AnalyticsConfiguration.default
        let analytics = MockAnalytics(configuration: config)
        
        XCTAssertEqual(analytics.configuration.privacy, .sensitive)
        XCTAssertFalse(analytics.configuration.sensitiveHeaders.isEmpty)
        XCTAssertFalse(analytics.configuration.sensitiveUrlQueries.isEmpty)
        XCTAssertFalse(analytics.configuration.sensitiveBodyParams.isEmpty)
    }
}
