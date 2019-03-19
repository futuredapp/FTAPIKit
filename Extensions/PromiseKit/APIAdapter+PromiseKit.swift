//
//  APIAdapter+PromiseKit.swift
//  FTAPIKit
//
//  Created by Matěj Jirásek on 03/01/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import PromiseKit

extension APIAdapter {
    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> Promise<Endpoint.Response> {
        let (promise, seal) = Promise<Endpoint.Response>.pending()
        request(response: endpoint) { result in
            switch result {
            case .value(let value):
                seal.fulfill(value)
            case .error(let error):
                seal.reject(error)
            }
        }
        return promise
    }

    public func request(data endpoint: APIEndpoint) -> Promise<Data> {
        let (promise, seal) = Promise<Data>.pending()
        request(data: endpoint) { result in
            switch result {
            case .value(let value):
                seal.fulfill(value)
            case .error(let error):
                seal.reject(error)
            }
        }
        return promise
    }
}
