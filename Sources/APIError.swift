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
    case client(Int, Data?)
    /// Error code returned by `APIAdapter`. Thrown when request fails
    /// with return code larger or equal to 400.
    case server(Int, Data?)
    /// Multipart body part error, when the stream for the part
    /// or the temporary request body stream cannot be opened.
    case multipartStreamCannotBeOpened
    /// Connection error when no response and data was recieved.
    case connection(Error)

    public init?(data: Data?, response: URLResponse?, error: Error?, decoder: JSONDecoder) {
        switch (data, response as? HTTPURLResponse, error) {
        case let (_, _, error as NSError) where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled:
            self = .cancelled
        case let (_, _, error?):
            self = .connection(error)
        case let (data, response?, nil) where 400..<500 ~= response.statusCode:
            self = .client(response.statusCode, data)
        case let (data, response?, nil) where 500..<600 ~= response.statusCode:
            self = .server(response.statusCode, data)
        case (_, .some, nil), (.some, nil, nil):
            return nil
        case (nil, nil, nil):
            fatalError("No response, data or error was returned from URLSession")
        }
    }
}
