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
    /// Undefined error. Return code is less than 400, but no
    /// request was received.
    case noResponse
    /// Error code returned by `APIAdapter`. When request fails
    /// with return code larger or equal to 400.
    case errorCode(Int, Data?)
}

/// Generic result type for API responses.
/// No operations are defined for this type,
/// it should be used manually or not at all
/// when some extension like PromiseKit is
/// used.
public enum APIResult<T> {
    /// Decoded response (or pure `Data` when decoding was not required).
    case value(T)
    /// Error returned by `APIAdapter`. The error will be of `APIError` type if
    /// custom error constuctor was not used.
    case error(Error)
}

/// HTTP method enum with all commonly used verbs.
public enum HTTPMethod: String, CustomStringConvertible {
    /// `OPTIONS` HTTP method
    case options
    /// `GET` HTTP method
    case get
    /// `HEAD` HTTP method
    case head
    /// `POST` HTTP method
    case post
    /// `PUT` HTTP method
    case put
    /// `PATCH` HTTP method
    case patch
    /// `DELETE` HTTP method
    case delete
    /// `TRACE` HTTP method
    case trace
    /// `CONNECT` HTTP method
    case connect

    /// Uppercased HTTP method, used for sending requests.
    public var description: String {
        return rawValue.uppercased()
    }
}

/// Alias for URL query or URL encoded parameter dictionary.
public typealias HTTPParameters = [String: String]
/// Alias for HTTP header dictionary.CustomStringConvertible
public typealias HTTPHeaders = [String: String]

public struct MultipartFile {
    let name, filename, mimeType: String
    let data: Data
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
