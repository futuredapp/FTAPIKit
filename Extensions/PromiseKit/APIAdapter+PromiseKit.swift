//
//  PromiseAPIAdapter.swift
//  Gastromapa
//
//  Created by Adam Salih on 12/09/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import PromiseKit

public struct CancellablePromise<T> {
    let promise: Promise<T>
    let trigger: APIAdapter.CancellationTrigger?
}

extension APIAdapter {
    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> Promise<Endpoint.Response> {
        return request(response:endpoint).promise
    }

    public func request(data endpoint: APIEndpoint) -> Promise<Data> {
        return request(data:endpoint).promise
    }

    @discardableResult
    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> CancellablePromise<Endpoint.Response> {
        var trigger: CancellationTrigger? = nil
        let promise = Promise<Endpoint.Response> { resolver in
            trigger = request(response: endpoint) { result in
                switch result {
                case .value(let value):
                    resolver.fulfill(value)
                case .error(let error):
                    resolver.reject(error)
                }
            }
        }

        return CancellablePromise(promise: promise, trigger: trigger)
    }

    @discardableResult
    public func request(data endpoint: APIEndpoint) -> CancellablePromise<Data> {
        var trigger: CancellationTrigger? = nil
        let promise = Promise<Data> { resolver in
            trigger = request(data: endpoint) { result in
                switch result {
                case .value(let value):
                    resolver.fulfill(value)
                case .error(let error):
                    resolver.reject(error)
                }
            }
        }

        return CancellablePromise(promise: promise, trigger: trigger)
    }
}
