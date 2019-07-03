//
//  Resolver+Result.swift
//  FTAPIKit
//
//  Created by Matěj Jirásek on 06/03/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import PromiseKit

extension Resolver {
    func resolve<E: Error>(result: Swift.Result<T, E>) {
        switch result {
        case .success(let value):
            fulfill(value)
        case .failure(let error):
            reject(error)
        }
    }
}
