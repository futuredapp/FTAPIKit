import Foundation
import FTNetworkTracer

class MockAnalytics: AnalyticsProtocol {
    var requestCount = 0
    var responseCount = 0
    var errorCount = 0
    var lastRequestId: String?
    var lastDuration: TimeInterval?

    let configuration: AnalyticsConfiguration = AnalyticsConfiguration(
        privacy: .none,
        unmaskedHeaders: [],
        unmaskedUrlQueries: [],
        unmaskedBodyParams: []
    )

    func track(_ entry: AnalyticEntry) {
        switch entry.type {
        case .request:
            requestCount += 1
        case .response:
            responseCount += 1
        case .error:
            errorCount += 1
        }
        lastRequestId = entry.requestId
        lastDuration = entry.duration
    }
}
