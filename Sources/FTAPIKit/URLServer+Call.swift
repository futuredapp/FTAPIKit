import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public extension URLServer {

    /// Performs call to andpoint which does not return no data in the HTTP response.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - completion: On success void, otherwise error.
    /// - Returns: The URLSessionTask representing this call. You can discard it, or keep it in case you want
    /// to abort the task before it's finished.
    @discardableResult
    func call(endpoint: Endpoint, completion: @escaping (Result<Void, ErrorType>) -> Void) -> URLSessionTask? {
        switch request(endpoint: endpoint) {
        case .success(let request):
            return call(request: request, file: uploadFile(endpoint: endpoint), completion: completion)
        case .failure(let error):
            completion(.failure(error))
            return nil
        }
    }

    /// Performs call to andpoint which returns an arbitrary data in the HTTP response, that should not be parsed by the decoder of the
    /// server.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - completion: On success plain data, otherwise error.
    /// - Returns: The URLSessionTask representing this call. You can discard it, or keep it in case you want
    /// to abort the task before it's finished.
    @discardableResult
    func call(data endpoint: Endpoint, completion: @escaping (Result<Data, ErrorType>) -> Void) -> URLSessionTask? {
        switch request(endpoint: endpoint) {
        case .success(let request):
            return call(data: request, file: uploadFile(endpoint: endpoint), completion: completion)
        case .failure(let error):
            completion(.failure(error))
            return nil
        }
    }

    /// Performs call to andpoint which returns data that are supposed to be parsed by the decoder of the instance
    /// conforming to `protocol Server` in the HTTP response.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - completion: On success instance of the required type, otherwise error.
    /// - Returns: The URLSessionTask representing this call. You can discard it, or keep it in case you want
    /// to abort the task before it's finished.
    @discardableResult
    func call<EP: ResponseEndpoint>(response endpoint: EP, completion: @escaping (Result<EP.Response, ErrorType>) -> Void) -> URLSessionTask? {
        switch request(endpoint: endpoint) {
        case .success(let request):
            return call(response: request, file: uploadFile(endpoint: endpoint), completion: completion)
        case .failure(let error):
            completion(.failure(error))
            return nil
        }
    }

    private func call(request: URLRequest, file: URL?, completion: @escaping (Result<Void, ErrorType>) -> Void) -> URLSessionTask? {
        task(request: request, file: file, process: { data, response, error in
            if let error = ErrorType(data: data, response: response, error: error, decoding: self.decoding) {
                return .failure(error)
            }
            return .success(())
        }, completion: completion)
    }

    private func call(data request: URLRequest, file: URL?, completion: @escaping (Result<Data, ErrorType>) -> Void) -> URLSessionTask? {
        task(request: request, file: file, process: { data, response, error in
            if let error = ErrorType(data: data, response: response, error: error, decoding: self.decoding) {
                return .failure(error)
            } else if let data = data {
                return .success(data)
            }
            return .failure(.unhandled)
        }, completion: completion)
    }

    private func call<R: Decodable>(response request: URLRequest, file: URL?, completion: @escaping (Result<R, ErrorType>) -> Void) -> URLSessionTask? {
        task(request: request, file: file, process: { data, response, error in
            if let error = ErrorType(data: data, response: response, error: error, decoding: self.decoding) {
                return .failure(error)
            } else if let data = data {
                do {
                    let response: R = try self.decoding.decode(data: data)
                    return .success(response)
                } catch {
                    return self.apiError(error: error)
                }
            }
            return .failure(.unhandled)
        }, completion: completion)
    }
}
