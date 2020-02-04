import Foundation

extension URLServer {
    @discardableResult
    public func call(request: URLRequest, completion: @escaping (Result<Void, ErrorType>) -> Void) -> URLSessionDataTask? {
        task(request: request, process: { data, response, error in
            if let error = ErrorType(data: data, response: response, error: error, decoding: self.decoding) {
                return .failure(error)
            }
            return .success(())
        }, completion: completion)
    }

    @discardableResult
    public func call(data request: URLRequest, completion: @escaping (Result<Data, ErrorType>) -> Void) -> URLSessionDataTask? {
        task(request: request, process: { data, response, error in
            if let error = ErrorType(data: data, response: response, error: error, decoding: self.decoding) {
                return .failure(error)
            } else if let data = data {
                return .success(data)
            }
            return .failure(.unhandled)
        }, completion: completion)
    }

    @discardableResult
    public func call<R: Decodable>(response request: URLRequest, completion: @escaping (Result<R, ErrorType>) -> Void) -> URLSessionDataTask? {
        task(request: request, process: { data, response, error in
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

    @discardableResult
    public func call(endpoint: Endpoint, completion: @escaping (Result<Void, ErrorType>) -> Void) -> URLSessionDataTask? {
        switch request(endpoint: endpoint) {
        case .success(let request):
            return call(request: request, completion: completion)
        case .failure(let error):
            completion(.failure(error))
            return nil
        }
    }


    @discardableResult
    public func call(data endpoint: Endpoint, completion: @escaping (Result<Data, ErrorType>) -> Void) -> URLSessionDataTask? {
        switch request(endpoint: endpoint) {
        case .success(let request):
            return call(data: request, completion: completion)
        case .failure(let error):
            completion(.failure(error))
            return nil
        }
    }

    @discardableResult
    public func call<EP: ResponseEndpoint>(response endpoint: EP, completion: @escaping (Result<EP.Response, ErrorType>) -> Void) -> URLSessionDataTask? {
        switch request(endpoint: endpoint) {
        case .success(let request):
            return call(response: request, completion: completion)
        case .failure(let error):
            completion(.failure(error))
            return nil
        }
    }

    func task<R>(
        request: URLRequest,
        process: @escaping (Data?, URLResponse?, Error?) -> Result<R, ErrorType>,
        completion: @escaping (Result<R, ErrorType>) -> Void
    ) -> URLSessionDataTask? {
        let task = urlSession.dataTask(with: request) { data, response, error in
            completion(process(data, response, error))
        }
        task.resume()
        return task
    }

    func request(endpoint: Endpoint) -> Result<URLRequest, ErrorType> {
        do {
            let builder = URLRequestBuilder(server: self, endpoint: endpoint)
            let request = try builder.build()
            return .success(request)
        } catch {
            return apiError(error: error)
        }
    }

    func apiError<S>(error: Error?) -> Result<S, ErrorType> {
        let error = ErrorType(data: nil, response: nil, error: error, decoding: decoding) ?? .unhandled
        return .failure(error)
    }
}
