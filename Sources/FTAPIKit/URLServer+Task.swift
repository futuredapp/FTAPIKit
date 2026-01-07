import Foundation

#if os(Linux)
import FoundationNetworking
#endif

extension URLServer {
    func task<R>(
        request: URLRequest,
        file: URL?,
        process: @escaping (Data?, URLResponse?, Error?) -> Result<R, ErrorType>,
        completion: @escaping (Result<R, ErrorType>) -> Void
    ) -> URLSessionDataTask? {
        if let file = file {
            return uploadTask(request: request, file: file, process: process, completion: completion)
        }
        return dataTask(request: request, process: process, completion: completion)
    }

    private func dataTask<R>(
        request: URLRequest,
        process: @escaping (Data?, URLResponse?, Error?) -> Result<R, ErrorType>,
        completion: @escaping (Result<R, ErrorType>) -> Void
    ) -> URLSessionDataTask? {
        let tokens = networkObservers.map { RequestToken(observer: $0, request: request) }

        let task = urlSession.dataTask(with: request) { data, response, error in
            tokens.forEach { $0.didReceiveResponse(response, data) }

            let result = process(data, response, error)

            if case let .failure(apiError) = result {
                tokens.forEach { $0.didFail(apiError) }
            }

            completion(result)
        }
        task.resume()
        return task
    }

    private func uploadTask<R>(
        request: URLRequest,
        file: URL,
        process: @escaping (Data?, URLResponse?, Error?) -> Result<R, ErrorType>,
        completion: @escaping (Result<R, ErrorType>) -> Void
    ) -> URLSessionUploadTask? {
        let tokens = networkObservers.map { RequestToken(observer: $0, request: request) }

        let task = urlSession.uploadTask(with: request, fromFile: file) { data, response, error in
            tokens.forEach { $0.didReceiveResponse(response, data) }

            let result = process(data, response, error)

            if case let .failure(apiError) = result {
                tokens.forEach { $0.didFail(apiError) }
            }

            completion(result)
        }
        task.resume()
        return task
    }

    func downloadTask(
        request: URLRequest,
        process: @escaping (URL?, URLResponse?, Error?) -> Result<URL, ErrorType>,
        completion: @escaping (Result<URL, ErrorType>) -> Void
    ) -> URLSessionDownloadTask? {
        let tokens = networkObservers.map { RequestToken(observer: $0, request: request) }

        let task = urlSession.downloadTask(with: request) { url, response, error in
            tokens.forEach { $0.didReceiveResponse(response, nil) }

            let result = process(url, response, error)

            if case let .failure(apiError) = result {
                tokens.forEach { $0.didFail(apiError) }
            }

            completion(result)
        }
        task.resume()
        return task
    }

    func request(endpoint: Endpoint) -> Result<URLRequest, ErrorType> {
        do {
            let request = try buildRequest(endpoint: endpoint)
            return .success(request)
        } catch {
            return apiError(error: error)
        }
    }

    func uploadFile(endpoint: Endpoint) -> URL? {
        #if !os(Linux)
        if let endpoint = endpoint as? UploadEndpoint {
            return endpoint.file
        }
        #endif
        return nil
    }

    func apiError<S>(error: Error?) -> Result<S, ErrorType> {
        let error = ErrorType(data: nil, response: nil, error: error, decoding: decoding) ?? .unhandled
        return .failure(error)
    }
}

// This hides the specific 'Context' type inside closures.
private struct RequestToken: Sendable {
    let didReceiveResponse: @Sendable (URLResponse?, Data?) -> Void
    let didFail: @Sendable (Error) -> Void

    // The generic 'T' captures the specific observer type and its associated Context
    init<T: NetworkObserver>(observer: T, request: URLRequest) {
        // We generate the context immediately upon initialization
        let context = observer.willSendRequest(request)

        // We capture the specific 'observer' and 'context' inside these closures
        self.didReceiveResponse = { [weak observer] response, data in
            observer?.didReceiveResponse(for: request, response: response, data: data, context: context)
        }

        self.didFail = { [weak observer] error in
            observer?.didFail(request: request, error: error, context: context)
        }
    }
}
