//
//  TransformProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 5/4/19.
//

import Foundation
import ProcedureKit

/// Creates transform procedure using given closure.
public class AnyTransformProcedureFactory<Input, Output> {
    /// Unified type for sync and async transform closures
    public enum Transformation {
        public typealias Sync = TransformProcedure<Input, Output>.Transform
        public typealias Async = AsyncTransformProcedure<Input, Output>.Transform
        /// Sync transformation
        case sync(Sync)
        /// Async transformation
        case async(Async)
    }

    private let transformation: Transformation

    /// Creates `AnyTransformProcedureFactory` with given sync closure
    ///
    /// - parameter sync: closure that should be used in transform procedures
    /// created by `AnyTransformProcedureFactory`
    public init(sync: @escaping Transformation.Sync) {
        self.transformation = .sync(sync)
    }

    /// Creates `AnyTransformProcedureFactory` with given async closure
    ///
    /// - parameter async: closure that should be used in transform procedures
    /// created by `AnyTransformProcedureFactory`
    public init(async: @escaping Transformation.Async) {
        self.transformation = .async(async)
    }

    /// Creates transform procedure with closure provided in initializer
    ///
    /// - returns: procedure that wraps closure provided in initializer wrapped into `AnyInputProcedure`
    public func anyInputProcedure() -> AnyInputProcedure<Input> {
        switch self.transformation {
        case .sync(let transformation): return AnyInputProcedure(TransformProcedure(transform: transformation))
        case .async(let transformation): return AnyInputProcedure(AsyncTransformProcedure(transform: transformation))
        }
    }
    
    /// Creates transform procedure with closure provided in initializer
    ///
    /// - returns: procedure that wraps closure provided in initializer wrapped into `AnyProcedure`
    public func anyProcedure() -> AnyProcedure<Input, Output> {
        switch self.transformation {
        case .sync(let transformation): return AnyProcedure(TransformProcedure(transform: transformation))
        case .async(let transformation): return AnyProcedure(AsyncTransformProcedure(transform: transformation))
        }
    }
}
