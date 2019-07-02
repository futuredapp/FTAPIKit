//
//  APIAdapter.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 08/02/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

/// Delegate of `APIAdapter` used for platform-specific functionality
/// (showing/hiding network activity indicator) and signing/manipulating
/// URL request before they are sent.
public protocol APIAdapterDelegate: class {
    /// Delegate method updating number of currently running requests. Should be used mainly
    /// for logging, debugging and/or presenting network activity indicator on iOS. See example
    /// implementation in discussion.
    ///
    ///     func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt) {
    ///         let isVisible = UIApplication.shared.isNetworkActivityIndicatorVisible
    ///         if runningRequestCount > 0, !isVisible {
    ///             UIApplication.shared.isNetworkActivityIndicatorVisible = true
    ///         } else if runningRequestCount < 1 {
    ///             UIApplication.shared.isNetworkActivityIndicatorVisible = false
    ///         }
    ///     }
    func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt)

    /// Method for updating `URLRequest` created by API adapter with app-specific headers etc.
    /// It can be completed asynchronously so actions like refreshing access token can be executed.
    /// Changes to URL request, which are not due to authorization requirements should be provided
    /// in custom `URLSession` with configuration when `APIAdapter` is created.
    ///
    /// The `authorization` property of `APIEndpoint` is provided for manual checking whether the
    /// request should be signed, because signing non-authorized endpoints might pose as a security risk.
    func apiAdapter(_ apiAdapter: APIAdapter, willRequest request: URLRequest, to endpoint: APIEndpoint, completion: @escaping (Result<URLRequest, Error>) -> Void)
}

/// Protocol describing interface communicating with API resources (most probably over internet).
/// This interface encapsulates executing requests.
///
/// Standard implementation of this interface using `URLSession` is available as
/// `URLSessionAPIAdapter`.
public protocol APIAdapter {

    /// Delegate used for notificating about the currently running request count
    /// and asynchronously signing authorized requests.
    var delegate: APIAdapterDelegate? { get set }

    /// Calls API request endpoint with JSON body and after finishing it calls completion handler with either decoded JSON model or error.
    ///
    /// - Parameters:
    ///   - endpoint: Response endpoint
    ///   - completion: Completion closure receiving result with automatically decoded JSON model taken from reponse endpoint associated type.
    func request<Endpoint: APIResponseEndpoint>(response endpoint: Endpoint, completion: @escaping (Result<Endpoint.Response, Error>) -> Void)

    /// Calls API endpoint and after finishing it calls completion handler with either data or error.
    ///
    /// - Parameters:
    ///   - endpoint: Standard endpoint with no response associated type.
    ///   - completion: Completion closure receiving result with data.
    func request(data endpoint: APIEndpoint, completion: @escaping (Result<Data, Error>) -> Void)
}
