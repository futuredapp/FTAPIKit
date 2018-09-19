//
//  MockupAPIAdapterDelegate.swift
//  FuntastyKit-iOS
//
//  Created by Matěj Kašpar Jirásek on 03/09/2018.
//  Copyright © 2018 The Funtasty. All rights reserved.
//

import FTAPIKit
import Foundation

final class MockupAPIAdapterDelegate: APIAdapterDelegate {
    func apiAdapter(_ apiAdapter: APIAdapter, willRequest request: URLRequest, to endpoint: APIEndpoint, completion: @escaping (URLRequest) -> Void) {
        if endpoint.authorized {
            var newRequest = request
            newRequest.addValue("Bearer " + UUID().uuidString, forHTTPHeaderField: "Authorization")
            completion(newRequest)
        } else {
            completion(request)
        }
    }

    func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt) {
    }
}
