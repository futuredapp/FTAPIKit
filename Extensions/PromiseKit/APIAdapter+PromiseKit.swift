//
//  APIAdapter+PromiseKit.swift
//  FTAPIKit
//
//  Created by Matěj Jirásek on 03/01/2019.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import PromiseKit

extension APIAdapter {
    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> Promise<Endpoint.Response> {
        return Promise<Endpoint.Response> { resolver in
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

    public func request(data endpoint: APIEndpoint) -> Promise<Data> {
        return Promise<Data> { resolver in
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
