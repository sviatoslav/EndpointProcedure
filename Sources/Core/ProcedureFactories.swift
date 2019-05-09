//
//  ProcedureFactories.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 3/23/19.
//

import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif

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

public struct AnyValidationProcedureFactory: ValidationProcedureFactory {
    public static let empty
        = AnyValidationProcedureFactory(AnyInputProcedure(TransformProcedure<HTTPResponseData, Void> {_ in}))
    private let procedureCreator: () -> AnyInputProcedure<HTTPResponseData>
    public init(_ creator: @autoclosure @escaping () -> AnyInputProcedure<HTTPResponseData>) {
        self.procedureCreator = creator
    }
    public func validationProcedure() -> AnyInputProcedure<HTTPResponseData> {
        return self.procedureCreator()
    }
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

public struct AnyInterceptionProcedureFactory: InterceptionProcedureFactory {
    public static let empty
        = AnyInterceptionProcedureFactory(AnyProcedure(TransformProcedure<Any, Any> { $0 }))
    private let procedureCreator: () -> AnyProcedure<Any, Any>
    public init(_ creator: @autoclosure @escaping () -> AnyProcedure<Any, Any>) {
        self.procedureCreator = creator
    }
    public func interceptionProcedure() -> AnyProcedure<Any, Any> {
        return self.procedureCreator()
    }
}

/// A type that can create response mapping procedure
public protocol ResponseMappingProcedureFactory {
    /// Creates response mapping procedure
    ///
    /// - parameter type: type of result
    func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T>
}
