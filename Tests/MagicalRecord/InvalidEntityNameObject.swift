//
//  InvalidEntityNameObject.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/17/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import CoreData

class InvalidEntityNameObject: NSManagedObject {
    @objc class func entityName() -> String {
        return "TestObject"
    }
}
