import Foundation
#if os(Linux)
import FoundationNetworking
#endif

public extension URLServer {

    /// Performs call to endpoint which does not return any data in the HTTP response.
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws an APIError if the request fails or server returns an error
    /// - Returns: Void on success
    func call(endpoint: Endpoint) async throws {
        let urlRequest = try await buildRequest(endpoint: endpoint)

        #if !os(Linux)
        let file = (endpoint as? UploadEndpoint)?.file
        #else
        let file: URL? = nil
        #endif

        let (data, response): (Data, URLResponse)
        if let file = file {
            (data, response) = try await urlSession.upload(for: urlRequest, fromFile: file)
        } else {
            (data, response) = try await urlSession.data(for: urlRequest)
        }

        if let error = ErrorType(data: data, response: response, error: nil, decoding: decoding) {
            throw error
        }
    }

    /// Performs call to endpoint which returns arbitrary data in the HTTP response, that should not be parsed by the decoder.
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws an APIError if the request fails or server returns an error
    /// - Returns: Plain data returned with the HTTP Response
    func call(data endpoint: Endpoint) async throws -> Data {
        let urlRequest = try await buildRequest(endpoint: endpoint)

        #if !os(Linux)
        let file = (endpoint as? UploadEndpoint)?.file
        #else
        let file: URL? = nil
        #endif

        let (data, response): (Data, URLResponse)
        if let file = file {
            (data, response) = try await urlSession.upload(for: urlRequest, fromFile: file)
        } else {
            (data, response) = try await urlSession.data(for: urlRequest)
        }

        if let error = ErrorType(data: data, response: response, error: nil, decoding: decoding) {
            throw error
        }

        return data
    }

    /// Performs call to endpoint which returns data that are supposed to be parsed by the decoder.
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws an APIError if the request fails, server returns an error, or decoding fails
    /// - Returns: Instance of the required type
    func call<EP: ResponseEndpoint>(response endpoint: EP) async throws -> EP.Response {
        let urlRequest = try await buildRequest(endpoint: endpoint)

        #if !os(Linux)
        let file = (endpoint as? UploadEndpoint)?.file
        #else
        let file: URL? = nil
        #endif

        let (data, response): (Data, URLResponse)
        if let file = file {
            (data, response) = try await urlSession.upload(for: urlRequest, fromFile: file)
        } else {
            (data, response) = try await urlSession.data(for: urlRequest)
        }

        if let error = ErrorType(data: data, response: response, error: nil, decoding: decoding) {
            throw error
        }

        return try decoding.decode(data: data)
    }
}
