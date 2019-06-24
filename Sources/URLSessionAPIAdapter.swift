//
//  URLSessionAPIAdapter.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 10/11/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

// This class provides user with easy way to serialize access to a property in multiplatform environment. This class is written with future PropertyWrapper feature of swift in mind.
internal final class Serialized<Value> {

    // Synchronization queue for the property. Read or write to the property must be perforimed on this queue
    private let queue = DispatchQueue(label: "com.thefuntasty.ftapikit.serialization")

    // The value itself with did-set observing.
    private var _value: Value {
        didSet {
            didSetEvent?(oldValue, _value)
        }
    }

    // Did set observer for stored property. Notice, that didSet event is called on the synchronization queue. You should free this thread asap with async call, since complex operations would slow down sync access to the property.
   var didSetEvent: ((_ oldValue: Value, _ newValue: Value)->Void)?

    // Inserting initial value to the property. Notice, that this operation is NOT DONE on the synchronization queue.
    internal init(initialValue: Value) {
        _value = initialValue
    }

    // MARK: Property access

    // Synchronized access wrapper around stored property. Calls to the synchronization queue are sync, so evaluating this getter and setter migth take considerable amount of time.
   var wrappedValue: Value {
        get {
            return queue.sync {
                return _value
            }
        }
        set {
            queue.sync {
                _value = newValue
            }
        }
    }

    // It is enouraged to use this method to make more complex operations with the stored property, like read-and-write. Do not perform any time-demading operations in this block since it will stop other uses of the stored property.
    internal func asyncAccess(_ block: @escaping (inout Value)->Void) {
        queue.async {
            block(&self._value)
        }
    }
}

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

        runningRequestCount.didSetEvent = { [weak self] _, newValue in
            DispatchQueue.main.async {
                guard let self = self else { return }
                strongTemporarySelf.delegate?.apiAdapter(strongTemporarySelf, didUpdateRunningRequestCount: newValue)
            }
        }
    }

    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint, completion: @escaping (APIResult<Endpoint.Response>) -> Void) {
        dataTask(response: endpoint, creation: { _ in }, completion: completion)
    }

    public func request(data endpoint: APIEndpoint, completion: @escaping (APIResult<Data>) -> Void) {
        dataTask(data: endpoint, creation: { _ in }, completion: completion)
    }

    public func dataTask<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint, creation: @escaping (URLSessionTask) -> Void, completion: @escaping (APIResult<Endpoint.Response>) -> Void) {
        dataTask(data: endpoint, creation: creation) { result in
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

    public func dataTask(data endpoint: APIEndpoint, creation: @escaping (URLSessionTask) -> Void, completion: @escaping (APIResult<Data>) -> Void) {
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
            delegate.apiAdapter(self, willRequest: request, to: endpoint) { result in
                switch result {
                case .value(let request):
                    let task = self.send(request: request, completion: completion)
                    creation(task)
                case .error(let error):
                    completion(.error(error))
                }
            }
        } else {
            let task = self.send(request: request, completion: completion)
            creation(task)
        }
    }

    private func send(request: URLRequest, completion: @escaping (APIResult<Data>) -> Void) -> URLSessionTask {
        runningRequestCount.asyncAccess { $0 += 1 }
        return resumeDataTask(with: request) { result in
            self.runningRequestCount.asyncAccess { $0 -= 1 }
            completion(result)
        }
    }

    private func resumeDataTask(with request: URLRequest, completion: @escaping (APIResult<Data>) -> Void) -> URLSessionTask {
        let task = urlSession.dataTask(with: request) { [jsonDecoder, errorType] data, response, error in
            if let error = errorType.init(data: data, response: response, error: error, decoder: jsonDecoder) {
                completion(.error(error))
            } else {
                completion(.value(data ?? Data()))
            }
        }
        task.resume()
        return task
    }
}
