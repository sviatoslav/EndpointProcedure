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

class DecodingProcedureFactory: ResponseMappingProcedureFactory {
    func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
        guard let decodableType = T.self as? Decodable.Type else { fatalError() }
        return self.decodingProcedure(for: decodableType)
    }
    
    private func decodingProcedure<T: Decodable>(for type: T.Type) -> AnyProcedure<Any, T> {
        
    }
}
