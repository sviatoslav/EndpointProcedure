//
//  EnqueueableTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/20/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

extension Procedure {
    func enqueue() {
        ProcedureQueue().add(operation: self)
    }
}
