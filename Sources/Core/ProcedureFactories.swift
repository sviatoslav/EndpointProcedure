//
//  ProcedureFactories.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 3/23/19.
//

import Foundation
import ProcedureKit

/// A type that can create HTTP data loading procedure
public protocol HTTPRequestProcedureFactory {
    /// Creates HTTP data loading procedure, throws error if unable to create procedure.
    ///
    /// - parameter data: `HTTPRequestData` used in procedure creation
    func requestProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData>
}

/// A type that can create validation procedure
public protocol ValidationProcedureFactory {
    /// Creates validation procedure
    func validationProcedure() -> AnyInputProcedure<HTTPResponseData>
}

/// A type that can create data deserialization procedure
public protocol DataDeserializationProcedureFactory {
    /// Creates data deserilization procedure
    func dataDeserializationProcedure() -> AnyProcedure<Data, Any>
}

/// A type that can create interception procedure
public protocol InterceptionProcedureFactory {
    /// Creates interception procedure
    func interceptionProcedure() -> AnyProcedure<Any, Any>
}

/// A type that can create response mapping procedure
public protocol ResponseMappingProcedureFactory {
    /// Creates response mapping procedure
    ///
    /// - parameter type: type of result
    func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T>
}

/// Procedure factory that can be initialized with transformation closure.
///
/// Used as parent class for `AnyValidationProcedureFactory`, `AnyDataDeserializationProcedureFactory` and
/// `AnyInterceptionProcedureFactory`.
public class TransformBasedProcedureFactory<Input, Output> {
    let transformProcedureFactory: AnyTransformProcedureFactory<Input, Output>
    /// Creates `TransformBasedProcedureFactory` with given sync closure
    ///
    /// - parameter sync: closure that should be used in transform procedures
    /// created by `TransformBasedProcedureFactory`
    public init(_ transformation: @escaping AnyTransformProcedureFactory<Input, Output>.Transformation.Sync) {
        self.transformProcedureFactory = AnyTransformProcedureFactory(sync: transformation)
    }
    
    /// Creates `TransformBasedProcedureFactory` with given async closure
    ///
    /// - parameter async: closure that should be used in transform procedures
    /// created by `TransformBasedProcedureFactory`
    public init(_ transformation: @escaping AnyTransformProcedureFactory<Input, Output>.Transformation.Async) {
        self.transformProcedureFactory = AnyTransformProcedureFactory(async: transformation)
    }
}

/// Simple implementation of `ValidationProcedureFactory`.
///
/// Creates validation procedure using given closure.
public class AnyValidationProcedureFactory: TransformBasedProcedureFactory<HTTPResponseData, Void>,
                                            ValidationProcedureFactory {
    /// Procedure factory that creates empty procedures
    public static let empty = AnyValidationProcedureFactory({_ in})
    /// Creates validation procedure with closure provided in initializer
    ///
    /// - returns: procedure that wraps closure provided in initializer
    public func validationProcedure() -> AnyInputProcedure<HTTPResponseData> {
        return self.transformProcedureFactory.anyInputProcedure()
    }
}

/// Simple implementation of `DataDeserializationProcedureFactory`.
///
/// Creates deserialization procedure using given closure.
public class AnyDataDeserializationProcedureFactory: TransformBasedProcedureFactory<Data, Any>,
                                                    DataDeserializationProcedureFactory {
    /// Procedure factory that creates empty procedures
    public static let empty = AnyDataDeserializationProcedureFactory({ $0 })
    /// Creates deserialization procedure with closure provided in initializer
    ///
    /// - returns: procedure that wraps closure provided in initializer
    public func dataDeserializationProcedure() -> AnyProcedure<Data, Any> {
        return self.transformProcedureFactory.anyProcedure()
    }
}

/// Simple implementation of `InterceptionProcedureFactory`.
///
/// Creates validation procedure using given closure.
public class AnyInterceptionProcedureFactory: TransformBasedProcedureFactory<Any, Any>, InterceptionProcedureFactory {
    /// Procedure factory that creates empty procedures
    public static let empty = AnyInterceptionProcedureFactory({ $0 })
    /// Creates interception procedure with closure provided in initializer
    ///
    /// - returns: procedure that wraps closure provided in initializer
    public func interceptionProcedure() -> AnyProcedure<Any, Any> {
        return self.transformProcedureFactory.anyProcedure()
    }
}


