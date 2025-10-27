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
        let requestId = UUID().uuidString
        let startTime = Date()
        
        // Log request if logger is available
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            if let logger = networkLogger {
                logRequest(request, requestId: requestId, logger: logger)
            }
        }
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            // Log response if logger is available
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                if let logger = self.networkLogger {
                    self.logResponse(request, response: response, data: data, requestId: requestId, startTime: startTime, logger: logger)
                }
            }
            
            let result = process(data, response, error)
            
            // Log error if any and logger is available
            if case .failure(let error) = result {
                if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                    if let logger = self.networkLogger {
                        self.logError(request, error: error, data: nil, requestId: requestId, logger: logger)
                    }
                }
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
        let requestId = UUID().uuidString
        let startTime = Date()
        
        // Log request if logger is available
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            if let logger = networkLogger {
                logRequest(request, requestId: requestId, logger: logger)
            }
        }
        
        let task = urlSession.uploadTask(with: request, fromFile: file) { data, response, error in
            // Log response if logger is available
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                if let logger = self.networkLogger {
                    self.logResponse(request, response: response, data: data, requestId: requestId, startTime: startTime, logger: logger)
                }
            }
            
            let result = process(data, response, error)
            
            // Log error if any and logger is available
            if case .failure(let error) = result {
                if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                    if let logger = self.networkLogger {
                        self.logError(request, error: error, data: nil, requestId: requestId, logger: logger)
                    }
                }
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
        let requestId = UUID().uuidString
        let startTime = Date()
        
        // Log request if logger is available
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            if let logger = networkLogger {
                logRequest(request, requestId: requestId, logger: logger)
            }
        }
        
        let task = urlSession.downloadTask(with: request) { url, response, error in
            // Log response if logger is available
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                if let logger = self.networkLogger {
                    self.logResponse(request, response: response, data: nil, requestId: requestId, startTime: startTime, logger: logger)
                }
            }
            
            let result = process(url, response, error)
            
            // Log error if any and logger is available
            if case .failure(let error) = result {
                if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                    if let logger = self.networkLogger {
                        self.logError(request, error: error, data: nil, requestId: requestId, logger: logger)
                    }
                }
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
