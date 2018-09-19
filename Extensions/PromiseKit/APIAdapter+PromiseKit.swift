//
//  PromiseAPIAdapter.swift
//  Gastromapa
//
//  Created by Adam Salih on 12/09/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import PromiseKit

extension APIAdapter {
    func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> Promise<Endpoint.Response> {
        return Promise { resolver in
            request(response: endpoint) { result in
                switch result {
                case .value(let value):
                    resolver.fulfill(value)
                case .error(let error):
                    resolver.reject(error)
                }
            }
        }
    }

    func request(data endpoint: APIEndpoint) -> Promise<Data> {
        return Promise { resolver in
            request(data: endpoint) { result in
                switch result {
                case .value(let value):
                    resolver.fulfill(value)
                case .error(let error):
                    resolver.reject(error)
                }
            }
        }
    }
}
