//
//  EnqueueableTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/20/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

#if canImport(ProcedureKit)
import ProcedureKit
#endif

extension Procedure {
    func enqueue() {
        ProcedureQueue().add(operation: self)
    }
}
