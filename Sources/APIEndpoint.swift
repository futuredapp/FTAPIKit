//
//  APIEndpoint.swift
//  FuntastyKit-iOS
//
//  Created by Matěj Kašpar Jirásek on 04/09/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

public protocol APIEndpoint {
    var path: String { get }
    var parameters: HTTPParameters { get }
    var method: HTTPMethod { get }
    var type: RequestType { get }
    var authorized: Bool { get }
}

public extension APIEndpoint {
    var parameters: HTTPParameters {
        return [:]
    }

    var type: RequestType {
        return .jsonParams
    }

    var method: HTTPMethod {
        return .get
    }

    var authorized: Bool {
        return false
    }
}

public protocol APIResponseEndpoint: APIEndpoint {
    associatedtype Response: Decodable
}

public protocol APIRequestEndpoint: APIEndpoint {
    associatedtype Request: Encodable
    var body: Request { get }
    func encode(using jsonEncoder: JSONEncoder) throws -> Data
}

public extension APIRequestEndpoint {
    public var method: HTTPMethod {
        return .post
    }

    public var type: RequestType {
        return RequestType.jsonBody(body)
    }

    public func encode(using jsonEncoder: JSONEncoder) throws -> Data {
        return try jsonEncoder.encode(body)
    }
}

public typealias APIRequestResponseEndpoint = APIRequestEndpoint & APIResponseEndpoint
