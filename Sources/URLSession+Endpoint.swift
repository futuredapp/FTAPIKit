//
//  URSession+Endpoint.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 08/02/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

public extension URLSession {
    func dataTask(to endpoint: APIEndpoint, with configuration: APIConfiguration) throws -> URLSessionDataTask {
        let request = try endpoint.request(with: configuration)
        return dataTask(with: request)
    }

    func dataTask(to endpoint: APIEndpoint, with configuration: APIConfiguration, completion: @escaping (APIResult<Data>) -> Void) throws -> URLSessionDataTask {
        let request = try endpoint.request(with: configuration)
        return dataTask(with: request) { (data, response, error) in
            if let error = configuration.apiErrorType.init(data: data, response: response, error: error, decoder: configuration.decoder) {
                completion(.error(error))
            } else {
                completion(.value(data ?? Data()))
            }
        }
    }

    func downloadTask(to endpoint: APIEndpoint, with configuration: APIConfiguration) throws -> URLSessionDownloadTask {
        let request = try endpoint.request(with: configuration)
        return downloadTask(with: request)
    }
}
