//
//  MagicalRecordObjectsArrayMappingProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/18/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

#if canImport(ProcedureKit)
import ProcedureKit
#endif
#if canImport(MagicalRecord)
import MagicalRecord
#endif

/// Procedure used for objects array mapping. `T` should be `Array` of subclass of `NSManagedObject`
class MagicalRecordObjectsArrayMappingProcedure<T>: MagicalRecordMappingProcedure<T> {

    /// `T.Element.self` if `T == Array` and `T.Element: NSManagedObject`, `nil` otherwise
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
