//
//  EndpointProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 9/30/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

public protocol EndpointProcedureFactory {
    associatedtype Result
    func createOrThrow(with configuration: ConfigurationProtocol) throws -> EndpointProcedure<Result>
}

public extension EndpointProcedureFactory {
    func create(with configuration: ConfigurationProtocol) -> EndpointProcedure<Result> {
        let procedure: EndpointProcedure<Result>
        do {
            procedure = try self.createOrThrow(with: configuration)
        } catch let error {
            procedure = EndpointProcedure(error: error)
        }
        return procedure
    }
}
