//
//  AnyDataDeserializationProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 1/4/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif

/// Simple implementation of `DataDeserializationProcedureFactory`.
///
/// Creates deserialization procedure using given closure.
public struct AnyDataDeserializationProcedureFactory: DataDeserializationProcedureFactory {

    /// Unified type for sync and async deserialization closures
    public enum Deserialization {
        public typealias Sync = TransformProcedure<Data, Any>.Transform
        public typealias Async = AsyncTransformProcedure<Data, Any>.Transform
        /// Sync deserialization
        case sync(Sync)
        /// Async deserialization
        case async(Async)
    }

    private let deserialization: Deserialization

    /// Creates `AnyDataDeserializationProcedureFactory` with given `deserialization`.
    ///
    /// - parameter deserialization: deserializatin closure that should be used in deserialization procedures
    /// created by `AnyDataDeserializationProcedureFactory`
    private init(deserialization: Deserialization) {
        self.deserialization = deserialization
    }

    /// Creates `AnyDataDeserializationProcedureFactory` with given sync closure
    ///
    /// - parameter syncDeserialization: closure that should be used in deserialization procedures
    /// created by `AnyDataDeserializationProcedureFactory`
    public init(syncDeserialization: @escaping Deserialization.Sync) {
        self.init(deserialization: .sync(syncDeserialization))
    }

    /// Creates `AnyDataDeserializationProcedureFactory` with given async closure
    ///
    /// - parameter asyncDeserialization: closure that should be used in deserialization procedures
    /// created by `AnyDataDeserializationProcedureFactory`
    public init(asyncDeserialization: @escaping Deserialization.Async) {
        self.init(deserialization: .async(asyncDeserialization))
    }

    /// Creates deserialization procedure with closure provided in initializer
    ///
    /// - returns: procedure that wraps closure provided in initializer
    public func dataDeserializationProcedure() -> AnyProcedure<Data, Any> {
        switch self.deserialization {
        case .sync(let transformation): return AnyProcedure(TransformProcedure(transform: transformation))
        case .async(let transformation): return AnyProcedure(AsyncTransformProcedure(transform: transformation))
        }
    }
}
