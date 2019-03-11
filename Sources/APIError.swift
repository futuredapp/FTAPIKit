//
//  APIError.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 11/03/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import struct Foundation.Data

/// Standard API error returned in `APIResult` when no custom error
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
    case statusCode(Int, Data?)
    /// Multipart body part error, when the stream for the part
    /// or the temporary request body stream cannot be opened.
    case multipartStreamCannotBeOpened
}
