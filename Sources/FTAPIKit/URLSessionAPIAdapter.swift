//
//  URLSessionAPIAdapter.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 10/11/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

/// Standard and default implementation of `APIAdapter` protocol using `URLSession`.
public final class URLSessionAPIAdapter: APIAdapter {
    public weak var delegate: APIAdapterDelegate?

    private let urlSession: URLSession
    private let baseUrl: URL

    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    private let errorType: APIError.Type

    private var runningRequestCount: Serialized<UInt>

    /// Constructor for `APIAdapter` based on `URLSession`.
    ///
    /// - Parameters:
    ///   - baseUrl: Base URI for the server for all API calls this API adapter will be executing.
    ///   - jsonEncoder: Optional JSON encoder used for serialization of JSON models.
    ///   - jsonDecoder: Optional JSON decoder used for deserialization of JSON models.
    ///   - errorType: If we want custom method for error handling instead of returning `StandardAPIError`
    ///                This type needs to implement `APIError` protocol and its optional init requirement.
    ///   - urlSession: Optional URL session (otherwise the standard one will be used). Used mainly if we need
    ///                 our own `URLSessionConfiguration` or another way of caching (ephemeral session).
    public init(baseUrl: URL, jsonEncoder: JSONEncoder = JSONEncoder(), jsonDecoder: JSONDecoder = JSONDecoder(), errorType: APIError.Type = StandardAPIError.self, urlSession: URLSession = .shared) {
        self.baseUrl = baseUrl
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        self.errorType = errorType
        self.urlSession = urlSession
        self.runningRequestCount = Serialized(initialValue: 0)

        runningRequestCount.didSet = { [weak self] count in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                self.delegate?.apiAdapter(self, didUpdateRunningRequestCount: count)
            }
        }
    }

    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint, completion: @escaping (Result<Endpoint.Response, Error>) -> Void) {
        dataTask(response: endpoint, creation: { _ in }, completion: completion)
    }

    public func request(data endpoint: APIEndpoint, completion: @escaping (Result<Data, Error>) -> Void) {
        dataTask(data: endpoint, creation: { _ in }, completion: completion)
    }

    public func dataTask<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint, creation: @escaping (URLSessionTask) -> Void, completion: @escaping (Result<Endpoint.Response, Error>) -> Void) {
        dataTask(data: endpoint, creation: creation) { result in
            completion(result.flatMap { data in
                Result(catching: { try self.jsonDecoder.decode(Endpoint.Response.self, from: data) })
            })
        }
    }

    public func dataTask(data endpoint: APIEndpoint, creation: @escaping (URLSessionTask) -> Void, completion: @escaping (Result<Data, Error>) -> Void) {
        let url = baseUrl.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.description

        do {
            try request.setRequestType(endpoint.type, parameters: endpoint.parameters, using: jsonEncoder)
        } catch {
            completion(.failure(error))
            return
        }

        if let delegate = delegate {
            delegate.apiAdapter(self, willRequest: request, to: endpoint) { result in
                switch result {
                case .success(let request):
                    let task = self.send(request: request, completion: completion)
                    creation(task)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            let task = self.send(request: request, completion: completion)
            creation(task)
        }
    }

    private func send(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        runningRequestCount.asyncAccess { $0 + 1 }
        return resumeDataTask(with: request) { result in
            self.runningRequestCount.asyncAccess { $0 - 1 }
            completion(result)
        }
    }

    private func resumeDataTask(with request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        let task = urlSession.dataTask(with: request) { [jsonDecoder, errorType] data, response, error in
            if let error = errorType.init(data: data, response: response, error: error, decoder: jsonDecoder) {
                completion(.failure(error))
            } else {
                completion(.success(data ?? Data()))
            }
        }
        task.resume()
        return task
    }
}
