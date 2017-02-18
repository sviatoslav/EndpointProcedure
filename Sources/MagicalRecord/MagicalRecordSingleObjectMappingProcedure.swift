//
//  MagicalRecordSingleObjectMappingProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/18/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit
import MagicalRecord

class MagicalRecordSingleObjectMappingProcedure<T>: MagicalRecordMappingProcedure<T> {

    override class var managedObjectType: NSManagedObject.Type? {
        guard T.self != NSManagedObject.self else {
            return nil
        }
        return T.self as? NSManagedObject.Type
    }

    override func performMapping(with completion: (ProcedureResult<T>) -> Void) throws {
        guard let object = self.input.value as? [AnyHashable: Any] else {
            throw ProcedureKitError.requirementNotSatisfied()
        }
        guard let managedObjectType = type(of: self).managedObjectType else {
            throw MagicalRecordMappingProcedureError.unsupportedType
        }
        var importResult: T?
        if let moc = self.managedObjectContext {
            moc.performAndWait {
                importResult = managedObjectType.mr_import(from: object, in: moc) as? T
            }
        } else {
            MagicalRecord.save(blockAndWait: { moc in
                importResult = managedObjectType.mr_import(from: object, in: moc) as? T
            })
        }
        guard let result = importResult else {
            throw MagicalRecordMappingProcedureError.unableMapResponse
        }
        completion(.success(result))
    }
}
