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
        
        // Log and track request
        logAndTrackRequest(request: request, requestId: requestId)
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            // Log and track response
            self.logAndTrackResponse(
                request: request,
                response: response,
                data: data,
                requestId: requestId,
                startTime: startTime
            )
            
            let result = process(data, response, error)
            
            // Log and track error if any
            if case .failure(let error) = result {
                self.logAndTrackError(
                    request: request,
                    error: error,
                    requestId: requestId
                )
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
        
        // Log and track request
        logAndTrackRequest(request: request, requestId: requestId)
        
        let task = urlSession.uploadTask(with: request, fromFile: file) { data, response, error in
            // Log and track response
            self.logAndTrackResponse(
                request: request,
                response: response,
                data: data,
                requestId: requestId,
                startTime: startTime
            )
            
            let result = process(data, response, error)
            
            // Log and track error if any
            if case .failure(let error) = result {
                self.logAndTrackError(
                    request: request,
                    error: error,
                    requestId: requestId
                )
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
        
        // Log and track request
        logAndTrackRequest(request: request, requestId: requestId)
        
        let task = urlSession.downloadTask(with: request) { url, response, error in
            // Log and track response
            self.logAndTrackResponse(
                request: request,
                response: response,
                data: nil,
                requestId: requestId,
                startTime: startTime
            )
            
            let result = process(url, response, error)
            
            // Log and track error if any
            if case .failure(let error) = result {
                self.logAndTrackError(
                    request: request,
                    error: error,
                    requestId: requestId
                )
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
    
    // MARK: - Private Helpers
    
    private func logAndTrack(
        type: String,
        request: URLRequest,
        response: HTTPURLResponse? = nil,
        data: Data? = nil,
        error: Error? = nil,
        requestId: String,
        startTime: Date? = nil
    ) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "UNKNOWN"
        let headers = response?.allHeaderFields as? [String: String] ?? request.allHTTPHeaderFields
        let body = data ?? request.httpBody
        let statusCode = response?.statusCode
        let duration = startTime.map { Date().timeIntervalSince($0) }
        let errorString = error.map { String(describing: $0) }
        
        // Log if logger is available
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            if let logger = logger {
                let logEntryType: EntryType
                switch type {
                case "request":
                    logEntryType = .request(method: method, url: url)
                case "response":
                    logEntryType = .response(method: method, url: url, statusCode: statusCode ?? 0)
                case "error":
                    logEntryType = .error(method: method, url: url, error: errorString ?? "Unknown error")
                default:
                    logEntryType = .request(method: method, url: url)
                }
                
                let logEntry = LogEntry(
                    type: logEntryType,
                    headers: headers,
                    body: body,
                    duration: duration,
                    requestId: requestId
                )
                logger.log(logEntry)
            }
        }
        
        // Track analytics if available
        if let analytics = analytics {
            let analyticEntryType: EntryType
            switch type {
            case "request":
                analyticEntryType = .request(method: method, url: url)
            case "response":
                analyticEntryType = .response(method: method, url: url, statusCode: statusCode ?? 0)
            case "error":
                analyticEntryType = .error(method: method, url: url, error: errorString ?? "Unknown error")
            default:
                analyticEntryType = .request(method: method, url: url)
            }
            
            let analyticEntry = AnalyticEntry(
                type: analyticEntryType,
                headers: headers,
                body: body,
                duration: duration,
                requestId: requestId,
                configuration: analytics.configuration
            )
            analytics.track(analyticEntry)
        }
    }
    
    private func logAndTrackRequest(
        request: URLRequest,
        requestId: String
    ) {
        logAndTrack(
            type: "request",
            request: request,
            requestId: requestId
        )
    }
    
    private func logAndTrackResponse(
        request: URLRequest,
        response: URLResponse?,
        data: Data?,
        requestId: String,
        startTime: Date
    ) {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        logAndTrack(
            type: "response",
            request: request,
            response: httpResponse,
            data: data,
            requestId: requestId,
            startTime: startTime
        )
    }
    
    private func logAndTrackError(
        request: URLRequest,
        error: Error,
        requestId: String
    ) {
        logAndTrack(
            type: "error",
            request: request,
            error: error,
            requestId: requestId
        )
    }
}
