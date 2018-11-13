//
//  EncoderProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/28/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif

public enum DecodingProcedureError: Error {
    case outputDoesNotConformToDecodable
}

class DecodingProcedure<T>: Procedure, InputProcedure, OutputProcedure {
    
    var input: Pending<Any> = .pending
    var output: Pending<ProcedureResult<T>> = .pending
    /// `DataDecoder` used in `DecodingProcedure`
    let decoder: DataDecoder
    
    init(decoder: DataDecoder) {
        self.decoder = decoder
        super.init()
    }
    
    class var decodableType: Decodable.Type? {
        return T.self as? Decodable.Type
    }
    
    override func execute() {
        do {
            guard let decodableType = type(of: self).decodableType else {
                throw DecodingProcedureError.outputDoesNotConformToDecodable
            }
            let nestedData = try self.nestedDataInput()
            let decodableValue = try decodableType.value(from: nestedData, using: self.decoder)
            guard let result = decodableValue as? T else {
                throw DecodingProcedureError.outputDoesNotConformToDecodable
            }
            self.finish(withResult: .success(result))
        } catch let error {
            self.finish(withResult: .failure(error))
        }
    }
    
    private func nestedDataInput() throws -> NestedData {
        switch self.input.value {
        case let data as Data: return ([], data)
        case let nestedData as NestedData: return nestedData
        default: throw ProcedureKitError.requirementNotSatisfied()
        }
    }
}

extension Decodable {
    fileprivate static func value(from data: NestedData, using decoder: DataDecoder) throws -> Self {
        return try decoder.decode(Self.self, from: data.data, codingPath: data.codingPath)
    }
}
