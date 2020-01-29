//
//  APIError.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 11/03/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

public protocol APIError: Error {
    typealias Standard = APIErrorStandard

    init?(data: Data?, response: URLResponse?, error: Error?, decoding: Decoding)

    static var unhandled: Self { get }
}
