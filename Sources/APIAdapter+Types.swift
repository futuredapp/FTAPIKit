//
//  APIAdapter+Types.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 08/02/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

/// Generic result type for API responses.
/// No operations are defined for this type,
/// it should be used manually or not at all
/// when some extension like PromiseKit is
/// used.
public enum APIResult<T> {
    /// Successfully decoded response (or pure `Data` when decoding was not required).
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
    case multipart([MultipartBodyPart])
    /// The parameters will be encoded using Base64 encoding
    /// and sent in request body.
    case base64Upload
    /// For sending raw body input streams, uploading files etc.
    case upload(body: InputStream, mimeType: String)
}

public extension RequestType {
    static func upload(url: URL) throws -> RequestType {
        guard let inputStream = InputStream(url: url) else {
            throw StandardAPIError.multipartStreamCannotBeOpened
        }
        return .upload(body: inputStream, mimeType: url.mimeType)
    }
}
