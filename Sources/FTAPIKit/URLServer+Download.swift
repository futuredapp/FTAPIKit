import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public extension URLServer {

    /// Downloads a file from the specified endpoint to a temporary location.
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws an APIError if the request fails or server returns an error
    /// - Returns: The location of a temporary file where the server's response is stored.
    ///   You must move this file or open it for reading before the async function returns. Otherwise, the file
    ///   is deleted, and the data is lost.
    func download(endpoint: Endpoint) async throws -> URL {
        let urlRequest = try await buildRequest(endpoint: endpoint)
        let (localURL, response) = try await urlSession.download(for: urlRequest)

        let urlData = localURL.absoluteString.data(using: .utf8)
        if let error = ErrorType(data: urlData, response: response, error: nil, decoding: decoding) {
            throw error
        }

        return localURL
    }
}
