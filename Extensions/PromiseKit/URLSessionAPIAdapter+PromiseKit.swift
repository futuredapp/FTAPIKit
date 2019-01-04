//
//  URLSessionAPIAdapter+PromiseKit.swift
//  FTAPIKit
//
//  Created by Matěj Jirásek on 03/01/2019.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import PromiseKit

public struct APIDataTask<T> {
    public let dataTask: Promise<URLSessionTask>
    public let response: Promise<T>
}

extension URLSessionAPIAdapter {
    public func dataTask<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> APIDataTask<Endpoint.Response> {
        var dataTaskResolver: Resolver<URLSessionTask>?
        let dataTaskPromise = Promise<URLSessionTask> { resolver in
            dataTaskResolver = resolver
        }

        let responsePromise = Promise<Endpoint.Response> { resolver in
            dataTask(response: endpoint, creation: { dataTask in
                dataTaskResolver?.fulfill(dataTask)
            }, completion: { result in
                if dataTaskPromise.isPending {
                    dataTaskResolver?.reject(PMKError.cancelled)
                }
                switch result {
                case .value(let value):
                    resolver.fulfill(value)
                case .error(let error):
                    resolver.reject(error)
                }
            })
        }
        return APIDataTask(dataTask: dataTaskPromise, response: responsePromise)
    }

    public func dataTask(data endpoint: APIEndpoint) -> APIDataTask<Data> {
        var dataTaskResolver: Resolver<URLSessionTask>?
        let dataTaskPromise = Promise<URLSessionTask> { resolver in
            dataTaskResolver = resolver
        }

        let responsePromise = Promise<Data> { resolver in
            dataTask(data: endpoint, creation: { dataTask in
                dataTaskResolver?.fulfill(dataTask)
            }, completion: { result in
                if dataTaskPromise.isPending {
                    dataTaskResolver?.reject(PMKError.cancelled)
                }
                switch result {
                case .value(let value):
                    resolver.fulfill(value)
                case .error(let error):
                    resolver.reject(error)
                }
            })
        }
        return APIDataTask(dataTask: dataTaskPromise, response: responsePromise)
    }
}

