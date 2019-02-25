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
            if let error = configuration.error(from: data, response: response, error: error) {
                completion(.error(error))
                return
            }
            switch (data, response, error) {
            case let (nil, response as HTTPURLResponse, nil) where response.statusCode == 204:
                completion(.value(Data()))
            case let (data?, response as HTTPURLResponse, nil) where response.statusCode < 400:
                completion(.value(data))
            case let (_, _, error as NSError) where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled:
                completion(.error(APIError.cancelled))
            case let (_, _, error?):
                completion(.error(error))
            case let (data, response as HTTPURLResponse, nil):
                completion(.error(APIError.errorCode(response.statusCode, data)))
            default:
                completion(.error(APIError.noResponse))
            }
        }
    }

    func downloadTask(to endpoint: APIEndpoint, with configuration: APIConfiguration) throws -> URLSessionDownloadTask {
        let request = try endpoint.request(with: configuration)
        return downloadTask(with: request)
    }
}
