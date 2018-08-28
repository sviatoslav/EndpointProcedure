//
//  EncoderProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/28/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

class DecodingProcedure<T>: Procedure, InputProcedure, OutputProcedure {
    
    var input: Pending<Any> = .pending
    var output: Pending<ProcedureResult<T>> = .pending
}
