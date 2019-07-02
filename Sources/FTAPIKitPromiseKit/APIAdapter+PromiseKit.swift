//
//  APIAdapter+PromiseKit.swift
//  FTAPIKit
//
//  Created by Matěj Jirásek on 03/01/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import PromiseKit
#if NOIMPORT
import FTAPIKit
#endif

extension APIAdapter {
    public func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint) -> Promise<Endpoint.Response> {
        let (promise, seal) = Promise<Endpoint.Response>.pending()
        request(response: endpoint, completion: seal.resolve)
        return promise
    }

    public func request(data endpoint: APIEndpoint) -> Promise<Data> {
        let (promise, seal) = Promise<Data>.pending()
        request(data: endpoint, completion: seal.resolve)
        return promise
    }
}
