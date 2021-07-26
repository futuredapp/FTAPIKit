import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public extension URLServer {
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
