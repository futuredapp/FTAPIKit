import XCTest
@testable import FTAPIKitTests


#if swift(>=5.5) && os(Linux)
    // Async test are not yet available on linux.
    // https://forums.swift.org/t/async-await-and-xctest/44780
    // 
    //let _ = testCase(AsyncTests.allTests)
#endif

XCTMain([
    testCase(ResponseTests.allTests),
    testCase(URLQueryTests.allTests),
])
