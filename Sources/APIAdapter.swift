//
//  APIAdapter.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 08/02/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

/// Delegate of `APIAdapter` used for platform-specific functionality
/// (showing/hiding network activity indicator) and signing/manipulating
/// URL request before they are sent.
public protocol APIAdapterDelegate: class {
    /// Delegate method updating number of currently running requests. Should be used mainly
    /// for logging, debugging and/or presenting network activity indicator on iOS. See example
    /// implementation in discussion.
    ///
    ///     func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt) {
    ///         let isVisible = UIApplication.shared.isNetworkActivityIndicatorVisible
    ///         if runningRequestCount > 0, !isVisible {
    ///             UIApplication.shared.isNetworkActivityIndicatorVisible = true
    ///         } else if runningRequestCount < 1 {
    ///             UIApplication.shared.isNetworkActivityIndicatorVisible = false
    ///         }
    ///     }
    func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt)

    /// Method for updating `URLRequest` created by API adapter with app-specific headers etc.
    /// It can be completed asynchronously so actions like refreshing access token can be executed.
    /// Changes to URL request, which are not due to authorization requirements should be provided
    /// in custom `URLSession` with configuration when `APIAdapter` is created.
    ///
    /// The `authorization` property of `APIEndpoint` is provided for manual checking whether the
    /// request should be signed, because signing non-authorized endpoints might pose as a security risk.
    func apiAdapter(_ apiAdapter: APIAdapter, willRequest request: URLRequest, to endpoint: APIEndpoint, completion: @escaping (URLRequest) -> Void)
}

/// Protocol
public protocol APIAdapter {
    /// Delegate used for notificating about the currently running request count
    /// and asynchronously signing authorized requests.
    var delegate: APIAdapterDelegate? { get set }

    /// Calls API request endpoint with JSON body and after finishing it calls completion handler with either decoded JSON model or error.
    ///
    /// - Parameters:
    ///   - endpoint: Response endpoint
    ///   - completion: Completion closure receiving result with automatically decoded JSON model taken from reponse endpoint associated type.
    func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint, completion: @escaping (APIResult<Endpoint.Response>) -> Void)

    /// Calls API endpoint and after finishing it calls completion handler with either data or error.
    ///
    /// - Parameters:
    ///   - endpoint: Standard endpoint with no response associated type.
    ///   - completion: Completion closure receiving result with data.
    func request(data endpoint: APIEndpoint, completion: @escaping (APIResult<Data>) -> Void)
}

/// Standard and default implementation of `APIAdapter` protocol using `URLSession`.
public final class URLSessionAPIAdapter: APIAdapter {

    /// Custom error custructor typealias recieving values from data task execution
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

    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint, completion: @escaping (APIResult<Endpoint.Response>) -> Void) {
        request(data: endpoint) { result in
            switch result {
            case .value(let data):
                do {
                    let model = try self.jsonDecoder.decode(Endpoint.Response.self, from: data)
                    completion(.value(model))
                } catch {
                    completion(.error(error))
                }
            case .error(let error):
                completion(.error(error))
            }
        }
    }

    public func request(data endpoint: APIEndpoint, completion: @escaping (APIResult<Data>) -> Void) {
        let url = baseUrl.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.description

        do {
            try request.setRequestType(endpoint.type, parameters: endpoint.parameters, using: jsonEncoder)
        } catch {
            completion(.error(error))
            return
        }

        if let delegate = delegate {
            delegate.apiAdapter(self, willRequest: request, to: endpoint) { request in
                self.send(request: request, completion: completion)
            }
        } else {
            send(request: request, completion: completion)
        }
    }

    private func send(request: URLRequest, completion: @escaping (APIResult<Data>) -> Void) {
        runningRequestCount += 1
        resumeDataTask(with: request) { result in
            self.runningRequestCount -= 1
            completion(result)
        }
    }

    private func resumeDataTask(with request: URLRequest, completion: @escaping (APIResult<Data>) -> Void) {
        let task = urlSession.dataTask(with: request) { [customErrorConstructor, jsonDecoder] data, response, error in
            if let constructor = customErrorConstructor, let error = constructor(data, response, error, jsonDecoder) {
                completion(.error(error))
                return
            }
            switch (data, response, error) {
            case let (_, response as HTTPURLResponse, _) where response.statusCode == 204:
                completion(.value(Data()))
            case let (data?, response as HTTPURLResponse, nil) where response.statusCode < 400:
                completion(.value(data))
            case let (_, _, error?):
                completion(.error(error))
            case let (data, response as HTTPURLResponse, nil):
                completion(.error(APIError.errorCode(response.statusCode, data)))
            default:
                completion(.error(APIError.noResponse))
            }
        }
        task.resume()
    }
}
