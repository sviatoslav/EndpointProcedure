//
//  MagicalRecordMappingProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/18/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit
import MagicalRecord

enum MagicalRecordMappingProcedureInternalError: Error {
    case unoverridenPerformMappingMethod
}

/// Abstract class
class MagicalRecordMappingProcedure<T>: Procedure, InputProcedure, OutputProcedure {

    var input: Pending<Any> = .pending
    var output: Pending<ProcedureResult<T>> = .pending

    /// Context that is used for data manipulation inside `MagicalRecordMappingProcedure`.
    /// If `nil` set, `MagicalRecordMappingProcedure` will create context and save changes to persisten store.
    /// If not `nil`, `save` method will not be called.
    var managedObjectContext: NSManagedObjectContext?

    class var managedObjectType: NSManagedObject.Type? {
        return nil
    }

    /// Determines if procedure is valid. Procedure is valid if `managedObjectType != nil`
    final class var isValid: Bool {
        return self.managedObjectType != nil
    }

    final override func execute() {
        guard type(of: self).isValid else {
            self.finish(withResult: .failure(MagicalRecordMappingProcedureError.unsupportedType))
            return
        }
        do {
            try self.performMapping {
                self.finish(withResult: $0)
            }
        } catch let error {
            self.finish(withResult: .failure(error))
        }
    }

    /// Performs object mapping
    /// - parameter completion: closure that is called after mapping finished.
    ///
    /// Method should be overriden in subclasses
    /// ------------------------------------
    func performMapping(with completion: (ProcedureResult<T>) -> Void) throws {
        throw MagicalRecordMappingProcedureInternalError.unoverridenPerformMappingMethod
    }
}
