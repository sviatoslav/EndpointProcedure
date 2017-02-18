//
//  ResponseMappingProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/22/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

public protocol ResponseMappingProcedureFactory {
    func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T>
}
