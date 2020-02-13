import Foundation

public extension URLServer {
    @discardableResult
    func download(endpoint: Endpoint, completion: @escaping (Result<URL, ErrorType>) -> Void) -> URLSessionTask? {
        switch request(endpoint: endpoint) {
        case .success(let request):
            return download(request: request, completion: completion)
        case .failure(let error):
            completion(.failure(error))
            return nil
        }
    }

    private func download(request: URLRequest, completion: @escaping (Result<URL, ErrorType>) -> Void) -> URLSessionTask? {
        downloadTask(request: request, process: { url, response, error in
            let urlData = (url?.absoluteString.utf8).flatMap { Data($0) }
            if let error = ErrorType(data: urlData, response: response, error: error, decoding: self.decoding) {
                return .failure(error)
            } else if let url = url {
                return .success(url)
            }
            return .failure(.unhandled)
        }, completion: completion)
    }
}
