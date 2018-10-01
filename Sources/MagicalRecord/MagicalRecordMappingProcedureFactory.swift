//
//  MagicalRecordMappingProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/22/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import CoreData
#if canImport(ProcedureKit)
import ProcedureKit
#endif
#if canImport(EndpointProcedure)
import EndpointProcedure
#endif

/// `ResponseMappingProcedureFactory` that creates `MagicalRecordMappingProcedure`s
public class MagicalRecordMappingProcedureFactory: ResponseMappingProcedureFactory {

    /// Context that is used for data manipulation inside `MagicalRecordMappingProcedure`.
    /// If `nil` set, `MagicalRecordMappingProcedure` will create context and save changes to persisten store.
    /// If not `nil`, `save` method will not be called.
    public let managedObjectContext: NSManagedObjectContext?

    /// Creates MagicalRecordMappingProcedureFactory
    ///
    /// - parameter managedObjectContext: context that should be used for
    /// data manipulation inside `MagicalRecordMappingProcedure`. If `nil` set,
    /// `MagicalRecordMappingProcedure` will create context and save changes to persisten store. 
    /// If not `nil`, `save` method will not be called. Default value: `nil`
    public init(managedObjectContext: NSManagedObjectContext? = nil) {
        self.managedObjectContext = managedObjectContext
    }

    /// Creates response mapping procedure for `NSManagedObject` subclasses
    /// or `Array` of `NSManagedObject` subclass.
    ///
    /// - throws: `MagicalRecordMappingProcedureError.unsupportedType` if `type` is not `NSManagedObject` subclass, 
    /// nor `Array` of `NSManagedObject` subclass.
    /// - parameter type: type of result
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
