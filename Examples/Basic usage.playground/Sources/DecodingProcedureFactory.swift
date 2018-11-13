//
//  DecodingProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/28/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
#if canImport(EndpointProcedure)
import EndpointProcedure
#endif
#if canImport(ProcedureKit)
import ProcedureKit
#endif

/// Type that can be used as `DecodingProcedure`'s input, if requested data is under coding key path
public typealias NestedData = (codingPath: [CodingKey], data: Data)

/// `ResponseMappingProcedureFactory` that creates `DecodingProcedure`s
public struct DecodingProcedureFactory: ResponseMappingProcedureFactory {
    /// `DataDecoder` used in `DecodingProcedure`
    public let decoder: DataDecoder

    /// Creates `DecodingProcedureFactory`
    ///
    /// - parameter decoder: `DataDecoder` that should be used in `DecodingProcedure`
    public init(decoder: DataDecoder) {
        self.decoder = decoder
    }

    /// Creates response mapping procedure for type conforming to `Decodable` protocol.
    ///
    /// - throws: `DecodingProcedureError.outputDoesNotConformToDecodable` if `type` does not conform to `Decodable`
    /// protocol.
    /// - parameter type: type of result
    public func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
        guard DecodingProcedure<T>.decodableType != nil else {
            throw DecodingProcedureError.outputDoesNotConformToDecodable
        }
        return AnyProcedure<Any, T>(DecodingProcedure<T>(decoder: self.decoder))
    }
}
