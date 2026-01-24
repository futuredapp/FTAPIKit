import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public extension URLServer {

    /// Downloads a file from the specified endpoint to a temporary location.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an APIError if the request fails or server returns an error
    /// - Returns: The location of a temporary file where the server's response is stored.
    ///   You must move this file or open it for reading before the async function returns. Otherwise, the file
    ///   is deleted, and the data is lost.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    func download(endpoint: Endpoint, configuring: RequestConfiguring? = nil) async throws -> URL {
        var urlRequest = try await buildRequest(endpoint: endpoint)
        try await configuring?.configure(&urlRequest)
        let (localURL, response) = try await urlSession.download(for: urlRequest)

        let urlData = localURL.absoluteString.data(using: .utf8)
        if let error = ErrorType(data: urlData, response: response, error: nil, decoding: decoding) {
            throw error
        }

        return localURL
    }
}
