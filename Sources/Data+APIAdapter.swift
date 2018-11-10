//
//  Data+APIAdapter.swift
//  FTAPIKit-iOS
//
//  Created by Matěj Kašpar Jirásek on 03/09/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import struct Foundation.Data

extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }

    mutating func appendRow(_ string: String? = nil) {
        if let string = string {
            append(string)
        }
        append("\r\n")
    }
}
