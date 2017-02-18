//
//  MagicalRecordObjectsArrayMappingProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/18/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit
import MagicalRecord

class MagicalRecordObjectsArrayMappingProcedure<T>: MagicalRecordMappingProcedure<T> {

    override class var managedObjectType: NSManagedObject.Type? {
        guard let elementsContainerType = T.self as? ElementsContainer.Type else {
            return nil
        }
        guard NSManagedObject.self != elementsContainerType.elementType else {
            return nil
        }
        return elementsContainerType.elementType as? NSManagedObject.Type
    }

    override func performMapping(with completion: (ProcedureResult<T>) -> Void) throws {
        guard let array = self.input.value as? [[AnyHashable: Any]] else {
            throw ProcedureKitError.requirementNotSatisfied()
        }
        guard let managedObjectType = type(of: self).managedObjectType else {
            throw MagicalRecordMappingProcedureError.unsupportedType
        }
        guard managedObjectType.mr_entityDescription() != nil else {
            throw MagicalRecordMappingProcedureError.unableMapResponse
        }
        var importResult: T?
        if let moc = self.managedObjectContext {
            moc.performAndWait {
                importResult = managedObjectType.mr_import(from: array, in: moc) as? T
            }
        } else {
            MagicalRecord.save(blockAndWait: { moc in
                importResult = managedObjectType.mr_import(from: array, in: moc) as? T
            })
        }
        guard let result = importResult else {
            throw MagicalRecordMappingProcedureError.unableMapResponse
        }
        completion(.success(result))
    }
}
