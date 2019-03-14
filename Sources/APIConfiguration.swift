//
//  APIConfiguration.swift
//  FTAPIKit-iOS
//
//  Created by Matěj Kašpar Jirásek on 08/02/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

public protocol APIConfiguration {
    var baseUrl: URL { get }

    func encode(_ value: Encodable) throws -> Data
    func decode<T: Decodable>(from data: Data) throws -> T

    func error(from data: Data?, response: URLResponse?, error: Error?) -> Error?
}

public protocol APIJSONConfiguration: APIConfiguration {
    var jsonDecoder: JSONDecoder { get }
    var jsonEncoder: JSONEncoder { get }
}

public extension APIJSONConfiguration {
    func encode(_ value: Encodable) throws -> Data {
        return try jsonEncoder.encode(AnyEncodable(value))
    }

    func decode<T: Decodable>(from data: Data) throws -> T {
        return try jsonDecoder.decode(T.self, from: data)
    }

    func error(from data: Data?, response: URLResponse?, error: Error?) -> Error? {
        return error
    }
}
