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

class MagicalRecordMappingProcedure<T>: Procedure, InputProcedure, OutputProcedure {

    var input: Pending<Any> = .pending
    var output: Pending<ProcedureResult<T>> = .pending

    var managedObjectContext: NSManagedObjectContext?

    class var managedObjectType: NSManagedObject.Type? {
        return nil
    }

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

    func performMapping(with completion: (ProcedureResult<T>) -> Void) throws {
        throw MagicalRecordMappingProcedureInternalError.unoverridenPerformMappingMethod
    }
}
