import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public extension URLServer {

    /// Created an URLSession download task that call the specified endpoint, saves the result into a file and calls
    /// the handler.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - completion: On success, the location of a temporary file where the server’s response is stored.
    ///   You must move this file or open it for reading before your completion handler returns. Otherwise, the file
    ///   is deleted, and the data is lost. Error otherwise.
    /// - Returns: The URLSessionTask representing this call. You can discard it, or keep it in case you want
    /// to abort the task before it's finished.
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
