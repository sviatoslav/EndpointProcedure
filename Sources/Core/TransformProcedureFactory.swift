//
//  TransformProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 5/4/19.
//

import Foundation
import ProcedureKit

/// Creates deserialization procedure using given closure.
public struct AnyTransformProcedureFactory {
    public static let empty = AnyDataDeserializationProcedureFactory(syncDeserialization: { $0 })
    /// Unified type for sync and async deserialization closures
    public enum Transformation {
        public typealias Sync = TransformProcedure<Data, Any>.Transform
        public typealias Async = AsyncTransformProcedure<Data, Any>.Transform
        /// Sync deserialization
        case sync(Sync)
        /// Async deserialization
        case async(Async)
    }

    private let transformation: Transformation

    /// Creates `AnyTransformProcedureFactory` with given `transformation`.
    ///
    /// - parameter transformation: transformation closure that should be used in transform procedures
    /// created by `AnyTransformProcedureFactory`
    private init(transformation: Transformation) {
        self.transformation = transformation
    }

    /// Creates `AnyTransformProcedureFactory` with given sync closure
    ///
    /// - parameter sync: closure that should be used in transform procedures
    /// created by `AnyTransformProcedureFactory`
    public init(sync: @escaping Transformation.Sync) {
        self.init(transformation: .sync(sync))
    }

    /// Creates `AnyTransformProcedureFactory` with given async closure
    ///
    /// - parameter async: closure that should be used in transform procedures
    /// created by `AnyTransformProcedureFactory`
    public init(async: @escaping Transformation.Async) {
        self.init(transformation: .async(async))
    }

    /// Creates transform procedure with closure provided in initializer
    ///
    /// - returns: procedure that wraps closure provided in initializer
    public func transformProcedure() -> AnyProcedure<Data, Any> {
        switch self.transformation {
        case .sync(let transformation): return AnyProcedure(TransformProcedure(transform: transformation))
        case .async(let transformation): return AnyProcedure(AsyncTransformProcedure(transform: transformation))
        }
    }
}
