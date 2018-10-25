//
//  APIAdapter+Types.swift
//  FuntastyKit
//
//  Created by Matěj Jirásek on 08/02/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

// MARK: - API adapter error

public enum APIError: Error {
    case noResponse
    case errorCode(Int, Data?)
}

// MARK: - API result

public enum APIResult<T> {
    case value(T)
    case error(Error)
}

// MARK: - HTTP methods

public enum HTTPMethod: String, CustomStringConvertible {
    case options, get, head, post, put, patch, delete, trace, connect

    public var description: String {
        return rawValue.uppercased()
    }
}

// MARK: - API request types

public typealias HTTPParameters = [String: String]
public typealias HTTPHeaders = [String: String]

public struct MultipartFile {
    let name, filename, mimeType: String
    let data: Data

    public init(name: String, filename: String, mimeType: String, data: Data) {
        self.name = name
        self.filename = filename
        self.mimeType = mimeType
        self.data = data
    }
}

public enum RequestData {
    case urlQuery(HTTPParameters)
    case urlEncoded(HTTPParameters)
    case jsonParams(HTTPParameters)
    case jsonBody(Encodable)
    case json(body: Data, query: HTTPParameters)
    case multipart(HTTPParameters, [MultipartFile])
    case base64Upload(HTTPParameters)

    public static let empty: RequestData = .jsonParams([:])
}
