//
//  CharacterSet+APIAdapter.swift
//  FTAPIKit-iOS
//
//  Created by Radek Dolezal on 24/05/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

extension CharacterSet {
    private static let urlGeneralDelimiters: CharacterSet = [":", "/", "?", "#", "[", "]", "@"]
    private static let urlSubDelimiters: CharacterSet = ["!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="]
    private static let urlDelimiters = CharacterSet.urlGeneralDelimiters.union(.urlSubDelimiters)

    /// https://tools.ietf.org/html/rfc3986#section-2.2
    static let urlQueryNameValueAllowed = CharacterSet.urlQueryAllowed.subtracting(.urlDelimiters)
}
