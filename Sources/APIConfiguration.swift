//
//  APIConfiguration.swift
//  FTAPIKit-iOS
//
//  Created by Matěj Kašpar Jirásek on 08/02/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

public protocol APIDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}

public protocol APIEncoder {
    func encode<T>(_ value: T) throws -> Data where T: Encodable
}

public protocol APIConfiguration {
    var baseUrl: URL { get }
    var apiErrorType: APIError.Type { get }

    var decoder: APIDecoder { get }
    var encoder: APIEncoder { get }
}
