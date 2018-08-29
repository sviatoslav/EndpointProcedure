//
//  DecodingProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/28/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
import EndpointProcedure
import ProcedureKit

public typealias NestedData = (codingPath: [CodingKey], data: Data)

public struct DecodingProcedureFactory: ResponseMappingProcedureFactory {
    
    public let decoder: DataDecoder
    
    public func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
        guard DecodingProcedure<T>.decodableType != nil else {
            throw DecodingProcedureError.outputDoesNotConformToDecodable
        }
        return AnyProcedure<Any, T>(DecodingProcedure<T>(decoder: self.decoder))
    }
}
