import XCTest
@testable import FTAPIKitTests


// Async test are not yet available on linux.
// https://forums.swift.org/t/async-await-and-xctest/44780
// 
//let _ = testCase(AsyncTests.allTests)

XCTMain([
    testCase(ResponseTests.allTests),
    testCase(URLQueryTests.allTests),
])
