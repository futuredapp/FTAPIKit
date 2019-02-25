//
//  APIEndpoint+URLRequest.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 08/02/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

extension APIEndpoint {
    func request(with configuration: APIConfiguration) throws -> URLRequest {
        let url = configuration.baseUrl.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.description

        try request.setRequestType(type, parameters: parameters, using: configuration.encode)
        return request
    }
}
