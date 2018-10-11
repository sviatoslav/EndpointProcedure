//
//  ResponseMappingProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/22/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

#if canImport(ProcedureKit)
import ProcedureKit
#endif

/// A type that can create response mapping procedure
public protocol ResponseMappingProcedureFactory {
    /// Creates response mapping procedure
    ///
    /// - parameter type: type of result
    func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T>
}
