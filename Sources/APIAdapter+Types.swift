//
//  APIAdapter+Types.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 08/02/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

/// Standard API error returned in `Result` when no custom error
/// was parsed in the `APIAdapter` first and the response from server
/// was invalid.
public enum APIError: Error {
    /// Undefined error. Return code is less than 400, but no
    /// request was received.
    case noResponse
    /// Error raised by NSURLSession corresponding to NSURLErrorCancelled at
    /// domain NSURLErrorDomain.
    case cancelled
    /// Error code returned by `APIAdapter`. Thrown when request fails
    /// with return code larger or equal to 400.
    case errorCode(Int, Data?)
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

/// Type of the API request. JSON body and multipart requests
/// have associated values which are used as a body. The other
/// types only describe how the `HTTPParameters` are encoded.
public enum RequestType {
    /// The HTTP parameters will be added to URL as query.
    case urlQuery
    /// HTTP parameters will be sent as a URL encoded body.
    case urlEncoded
    /// The parameters will be sent as JSON body.
    case jsonParams
    /// The encodable model will be serialized and sent as JSON,
    /// parameters will be added as URL query.
    case jsonBody(Encodable)
    /// All the parameters will be sent as multipart
    /// and files too.
    case multipart([MultipartFile])
    /// The parameters will be encoded using Base64 encoding
    /// and sent in request body.
    case base64Upload
}

/// Multipart file model for multipart request types.
public struct MultipartFile: Hashable {
    let name, filename, mimeType: String
    let data: Data

    /// Public initializer for multipart files.
    ///
    /// - Parameters:
    ///   - name: Part name.
    ///   - filename: File name with extension.
    ///   - mimeType: MIME type of the file.
    ///   - data: File content.
    public init(name: String, filename: String, mimeType: String, data: Data) {
        self.name = name
        self.filename = filename
        self.mimeType = mimeType
        self.data = data
    }
}
