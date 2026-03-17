import Foundation

public extension URLServer {

    /// Downloads a file from the specified endpoint to a temporary location.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an APIError if the request fails or server returns an error
    /// - Returns: The location of a temporary file where the server's response is stored.
    ///   You must move this file or open it for reading before the async function returns. Otherwise, the file
    ///   is deleted, and the data is lost.
    func download(endpoint: Endpoint, configuring: RequestConfiguring? = nil) async throws -> URL {
        var urlRequest = try await buildRequest(endpoint: endpoint)
        try await configuring?.configure(&urlRequest)

        let observers = networkObservers.map { AnyObserverToken(observer: $0, request: urlRequest) }

        let (localURL, response): (URL, URLResponse)
        do {
            (localURL, response) = try await urlSession.download(for: urlRequest)
        } catch {
            observers.forEach { $0.didReceiveResponse(for: urlRequest, response: nil, data: nil) }
            observers.forEach { $0.didFail(request: urlRequest, error: error) }
            throw error
        }

        observers.forEach { $0.didReceiveResponse(for: urlRequest, response: response, data: nil) }

        let urlData = localURL.absoluteString.data(using: .utf8)
        if let error = ErrorType(data: urlData, response: response, error: nil, decoding: decoding) {
            observers.forEach { $0.didFail(request: urlRequest, error: error) }
            throw error
        }

        return localURL
    }
}
