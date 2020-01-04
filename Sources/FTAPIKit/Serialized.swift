//
//  Serialized.swift
//  FTAPIKit-iOS
//
//  Created by Patrik Potoček on 27/06/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

/// This class provides user with easy way to serialize access to a property in multiplatform environment. This class is written with future PropertyWrapper feature of swift in mind.
final class Serialized<Value> {

    /// Synchronization queue for the property. Read or write to the property must be perforimed on this queue
    private let queue = DispatchQueue(label: "com.thefuntasty.ftapikit.serialization")

    /// The value itself with did-set observing.
    private var value: Value {
        didSet {
            didSet?(value)
        }
    }

    /// Did set observer for stored property. Notice, that didSet event is called on the synchronization queue. You should free this thread asap with async call, since complex operations would slow down sync access to the property.
    var didSet: ((Value) -> Void)?

    /// Inserting initial value to the property. Notice, that this operation is NOT DONE on the synchronization queue.
    init(initialValue: Value) {
        value = initialValue
    }

    /// It is enouraged to use this method to make more complex operations with the stored property, like read-and-write. Do not perform any time-demading operations in this block since it will stop other uses of the stored property.
    func asyncAccess(transform: @escaping (Value) -> Value) {
        queue.async {
            self.value = transform(self.value)
        }
    }
}
