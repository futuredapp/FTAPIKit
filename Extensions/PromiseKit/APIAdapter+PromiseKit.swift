//
//  PromiseAPIAdapter.swift
//  Gastromapa
//
//  Created by Adam Salih on 12/09/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import PromiseKit

extension APIAdapter {
    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> Promise<Endpoint.Response> {
        return request(response:response).0
    }

    public func request(data endpoint: APIEndpoint) -> Promise<Data> {
        return request(data:data).0
    }

    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> (Promise<Endpoint.Response>, CancellationTrigger?) {
        let trigger: CancellationTrigger? = nil
        let promise = Promise { resolver in
            trigger = request(response: endpoint) { result in
                switch result {
                case .value(let value):
                    resolver.fulfill(value)
                case .error(let error):
                    resolver.reject(error)
                }
            }
        }

        return (promise, trigger)
    }

    public func request(data endpoint: APIEndpoint) -> (Promise<Data>, CancellationTrigger?) {
        let trigger: CancellationTrigger? = nil
        let promise = return Promise { resolver in
            trigger = request(data: endpoint) { result in
                switch result {
                case .value(let value):
                    resolver.fulfill(value)
                case .error(let error):
                    resolver.reject(error)
                }
            }
        }

        return (promise, trigger)
    }
}
