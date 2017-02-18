//
//  DataDeserializationProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 1/4/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

public protocol DataDeserializationProcedureFactory {
    func dataDeserializationProcedure() -> AnyProcedure<Data, Any>
}
