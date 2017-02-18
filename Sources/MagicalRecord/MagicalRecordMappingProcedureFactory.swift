//
//  MagicalRecordMappingProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/22/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import CoreData
import ProcedureKit
import EndpointProcedure

public class MagicalRecordMappingProcedureFactory: ResponseMappingProcedureFactory {
    public let managedObjectContext: NSManagedObjectContext?

    public init(managedObjectContext: NSManagedObjectContext? = nil) {
        self.managedObjectContext = managedObjectContext
    }

    public func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
        let magicalRecordMappingProcedure: MagicalRecordMappingProcedure<T>
        if MagicalRecordSingleObjectMappingProcedure<T>.isValid {
            magicalRecordMappingProcedure = MagicalRecordSingleObjectMappingProcedure<T>()
        } else if MagicalRecordObjectsArrayMappingProcedure<T>.isValid {
            magicalRecordMappingProcedure = MagicalRecordObjectsArrayMappingProcedure<T>()
        } else {
            throw MagicalRecordMappingProcedureError.unsupportedType
        }
        magicalRecordMappingProcedure.managedObjectContext = self.managedObjectContext
        return AnyProcedure(magicalRecordMappingProcedure)
    }
}
