//
//  MockupAPIAdapterDelegate.swift
//  FTAPIKit-iOS
//
//  Created by Matěj Kašpar Jirásek on 03/09/2018.
//  Copyright © 2018 The Funtasty. All rights reserved.
//

import FTAPIKit
import Foundation

final class MockupAPIAdapterDelegate: APIAdapterDelegate {
    func apiAdapter(_ apiAdapter: APIAdapter, willRequest request: URLRequest, to endpoint: Endpoint, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        if endpoint.authorized {
            var newRequest = request
            newRequest.addValue("Bearer " + UUID().uuidString, forHTTPHeaderField: "Authorization")
            completion(.success(newRequest))
        } else {
            completion(.success(request))
        }
    }

    func apiAdapter(_ apiAdapter: APIAdapter, didUpdateRunningRequestCount runningRequestCount: UInt) {
    }
}
