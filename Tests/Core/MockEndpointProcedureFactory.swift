//
//  MockEndpointProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 9/30/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit
#if ALL
@testable import All
#else
@testable import EndpointProcedure
#endif

class MockEndpointProcedureFactory: EndpointProcedureFactory, DefaultConfigurationProvider, HTTPDataLoadingProcedureFactory,
                                    DataDeserializationProcedureFactory, ResponseMappingProcedureFactory {

    static let error = NSError(domain: "MockProcedureFactoryDomain", code: -1235, userInfo: nil)

    let callback: (MockEndpointProcedureFactory, ConfigurationProtocol) -> Void
    let creation: (ConfigurationProtocol) throws -> EndpointProcedure<Result>

    init(callback: @escaping (MockEndpointProcedureFactory, ConfigurationProtocol) -> Void) {
        self.callback = callback
        self.creation = {_ in throw MockEndpointProcedureFactory.error }
    }

    init(procedureCreation: @escaping (ConfigurationProtocol) throws -> EndpointProcedure<Result>) {
        self.callback = {_,_ in}
        self.creation = procedureCreation
    }

    func dataLoadingProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData> {
        throw MockEndpointProcedureFactory.error
    }

    func dataDeserializationProcedure() -> AnyProcedure<Data, Any> {
        return AnyProcedure(TransformProcedure<Data, Any> {_ in throw MockEndpointProcedureFactory.error })
    }

    func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
        throw MockEndpointProcedureFactory.error
    }

    var defaultConfiguration: ConfigurationProtocol {
        return Configuration(dataLoadingProcedureFactory: self, dataDeserializationProcedureFactory: self,
                             responseMappingProcedureFactory: self)
    }

    func createOrThrow(with configuration: ConfigurationProtocol) throws -> EndpointProcedure<Void> {
        self.callback(self, configuration)
        return try self.creation(configuration)
    }
}
