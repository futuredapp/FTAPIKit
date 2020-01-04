//
//  AnyEncodable.swift
//  FTAPIKit
//
//  Created by Patrik Potoček on 27.3.18.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

struct AnyEncodable: Encodable {
    private let anyEncode: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        anyEncode = { encoder in
            try encodable.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try anyEncode(encoder)
    }
}
