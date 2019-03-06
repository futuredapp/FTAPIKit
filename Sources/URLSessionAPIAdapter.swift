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

    /// Custom error constructor typealias receiving values from data task execution
    /// and JSON decoder, if it needs to decode custom error from returned JSON.
    public typealias ErrorConstructor = (Data?, URLResponse?, Error?, JSONDecoder) -> Error?

    public weak var delegate: APIAdapterDelegate?

    private let urlSession: URLSession
    private let baseUrl: URL

    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    private let customErrorConstructor: ErrorConstructor?

    private var runningRequestCount: UInt = 0 {
        didSet {
            guard let delegate = delegate else { return }
            DispatchQueue.main.async {
                delegate.apiAdapter(self, didUpdateRunningRequestCount: self.runningRequestCount)
            }
        }
    }

    /// Constructor for `APIAdapter` based on `URLSession`.
    ///
    /// - Parameters:
    ///   - baseUrl: Base URI for the server for all API calls this API adapter will be executing.
    ///   - jsonEncoder: Optional JSON encoder used for serialization of JSON models.
    ///   - jsonDecoder: Optional JSON decoder used for deserialization of JSON models.
    ///   - customErrorConstructor: Optional custom error constructor if we want the API adapter to not return
    ///                             the standard `APIError`, but to handle the errors our own way.
    ///   - urlSession: Optional URL session (otherwise the standard one will be used). Used mainly if we need
    ///                 our own `URLSessionConfiguration` or another way of caching (ephemeral session).
    public init(baseUrl: URL, jsonEncoder: JSONEncoder = JSONEncoder(), jsonDecoder: JSONDecoder = JSONDecoder(), customErrorConstructor: ErrorConstructor? = nil, urlSession: URLSession = .shared) {
        self.baseUrl = baseUrl
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        self.customErrorConstructor = customErrorConstructor
        self.urlSession = urlSession
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
        runningRequestCount += 1
        return resumeDataTask(with: request) { result in
            self.runningRequestCount -= 1
            completion(result)
        }
    }

    private func resumeDataTask(with request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        let task = urlSession.dataTask(with: request) { [customErrorConstructor, jsonDecoder] data, response, error in
            if let constructor = customErrorConstructor, let error = constructor(data, response, error, jsonDecoder) {
                completion(.failure(error))
                return
            }
            switch (data, response, error) {
            case let (_, response as HTTPURLResponse, _) where response.statusCode == 204:
                completion(.success(Data()))
            case let (data?, response as HTTPURLResponse, nil) where response.statusCode < 400:
                completion(.success(data))
            case let (_, _, error as NSError) where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled:
                completion(.failure(APIError.cancelled))
            case let (_, _, error?):
                completion(.failure(error))
            case let (data, response as HTTPURLResponse, nil):
                completion(.failure(APIError.errorCode(response.statusCode, data)))
            default:
                completion(.failure(APIError.noResponse))
            }
        }
        task.resume()
        return task
    }
}
