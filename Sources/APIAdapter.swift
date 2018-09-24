//
//  APIAdapter.swift
//  FuntastyKit
//
//  Created by Matěj Jirásek on 08/02/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

public protocol APIAdapterDelegate: class {
    func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt)
    func apiAdapter(_ apiAdapter: APIAdapter, willRequest request: URLRequest, to endpoint: APIEndpoint, completion: @escaping (URLRequest) -> Void)
}

public typealias APIAdapterErrorConstructor = (Data?, URLResponse?, Error?, JSONDecoder) -> Error?

public protocol APIAdapter {
    var delegate: APIAdapterDelegate? { get set }

    func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint, completion: @escaping (APIResult<Endpoint.Response>) -> Void)
    func request(data endpoint: APIEndpoint, completion: @escaping (APIResult<Data>) -> Void)
}

public final class URLSessionAPIAdapter: APIAdapter {

    public weak var delegate: APIAdapterDelegate?

    private let urlSession: URLSession
    private let baseUrl: URL

    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    private let customErrorConstructor: APIAdapterErrorConstructor?

    private var runningRequestCount: UInt = 0 {
        didSet {
            guard let delegate = delegate else { return }
            DispatchQueue.main.async {
                delegate.apiAdapter(self, didUpdateRunningRequestCount: self.runningRequestCount)
            }
        }
    }

    public init(baseUrl: URL, jsonEncoder: JSONEncoder = JSONEncoder(), jsonDecoder: JSONDecoder = JSONDecoder(), customErrorConstructor: APIAdapterErrorConstructor? = nil, urlSession: URLSession = .shared) {
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
            try request.setRequestData(endpoint.data, using: jsonEncoder)
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
        let task = urlSession.dataTask(with: request) { data, response, error in
            switch (data, response, error) {
            case let (_, response as HTTPURLResponse, _) where response.statusCode == 204:
                completion(.value(Data()))
            case let (data?, response as HTTPURLResponse, nil) where response.statusCode < 400:
                if let constructor = self.customErrorConstructor, let error = constructor(data, response, error, self.jsonDecoder) {
                    completion(.error(error))
                } else {
                    completion(.value(data))
                }
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
