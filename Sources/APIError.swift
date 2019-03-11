//
//  APIError.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 11/03/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

public protocol APIError: Error {
    init?(data: Data?, response: URLResponse?, error: Error?, decoder: JSONDecoder)
}

/// Standard API error returned in `APIResult` when no custom error
/// was parsed in the `APIAdapter` first and the response from server
/// was invalid.
public enum StandardAPIError: APIError {
    /// Undefined error. Return code is less than 400, but no
    /// request was received.
    case noResponse
    /// Error raised by NSURLSession corresponding to NSURLErrorCancelled at
    /// domain NSURLErrorDomain.
    case cancelled
    /// Error code returned by `APIAdapter`. Thrown when request fails
    /// with return code larger or equal to 400.
    case statusCode(Int, Data?)
    /// Multipart body part error, when the stream for the part
    /// or the temporary request body stream cannot be opened.
    case multipartStreamCannotBeOpened
    case underlyingError(Error)

    public init?(data: Data?, response: URLResponse?, error: Error?, decoder: JSONDecoder) {
        switch (data, response, error) {
        case let (_, response as HTTPURLResponse, _) where response.statusCode == 204:
            return nil
        case let (.some, response as HTTPURLResponse, nil) where response.statusCode < 400:
            return nil
        case let (_, _, error as NSError) where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled:
            self = .cancelled
        case let (_, _, error?):
            self = .underlyingError(error)
        case let (data, response as HTTPURLResponse, nil):
            self = .statusCode(response.statusCode, data)
        default:
            self = .noResponse
        }
    }
}
