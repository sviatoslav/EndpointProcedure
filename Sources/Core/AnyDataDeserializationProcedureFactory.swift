//
//  AnyDataDeserializationProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 1/4/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

public struct AnyDataDeserializationProcedureFactory: DataDeserializationProcedureFactory {

    public enum Deserialization {
        public typealias Sync = TransformProcedure<Data, Any>.Transform
        public typealias Async = AsyncTransformProcedure<Data, Any>.Transform
        case sync(Sync)
        case async(Async)
    }

    private let deserialization: Deserialization

    private init(deserialization: Deserialization) {
        self.deserialization = deserialization
    }

    public init(syncDeserialization: @escaping Deserialization.Sync) {
        self.init(deserialization: .sync(syncDeserialization))
    }

    public init(asyncDeserialization: @escaping Deserialization.Async) {
        self.init(deserialization: .async(asyncDeserialization))
    }

    public func dataDeserializationProcedure() -> AnyProcedure<Data, Any> {
        switch self.deserialization {
        case .sync(let transformation): return AnyProcedure(TransformProcedure(transform: transformation))
        case .async(let transformation): return AnyProcedure(AsyncTransformProcedure(transform: transformation))
        }
    }
}
