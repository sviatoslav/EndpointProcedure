//
//  ConfigurationProtocol.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif

public protocol EndpointProcedureConfigurationProviding {
    func configuration<T>(forRequestData requestData: HTTPRequestData,
                          responseType: T.Type) -> AnyEndpointProcedureComponentsProvider<T>
}

public protocol EndpointProcedureComponentsProviding {
    associatedtype Response
    func requestProcedure() throws -> AnyOutputProcedure<HTTPResponseData>
    func validationProcedure() -> AnyInputProcedure<HTTPResponseData>
    func deserializationProcedure() -> AnyProcedure<Data, Any>
    func interceptionProcedure() -> AnyProcedure<Any, Any>
    func responseMappingProcedure() throws -> AnyProcedure<Any, Response>
}

public extension EndpointProcedureComponentsProviding {
    var wrapped: AnyEndpointProcedureComponentsProvider<Response> {
        return AnyEndpointProcedureComponentsProvider(self)
    }
    func validationProcedure() -> AnyInputProcedure<HTTPResponseData> {
        return AnyValidationProcedureFactory.empty.validationProcedure()
    }
    func deserializationProcedure() -> AnyProcedure<Data, Any> {
        return AnyDataDeserializationProcedureFactory.empty.dataDeserializationProcedure()
    }
    func interceptionProcedure() -> AnyProcedure<Any, Any> {
        return AnyInterceptionProcedureFactory.empty.interceptionProcedure()
    }
}

public struct ClosureBasedEndpointProcedureComponentsProvider<Response>: EndpointProcedureComponentsProviding {
    private let request: () throws -> AnyOutputProcedure<HTTPResponseData>
    private let validation: () -> AnyInputProcedure<HTTPResponseData>
    private let deserialization: () -> AnyProcedure<Data, Any>
    private let interception: () -> AnyProcedure<Any, Any>
    private let responseMapping: () throws -> AnyProcedure<Any, Response>

    public init(
        request: @autoclosure @escaping () throws -> AnyOutputProcedure<HTTPResponseData>,
        validation: @autoclosure @escaping () -> AnyInputProcedure<HTTPResponseData>
        = AnyValidationProcedureFactory.empty.validationProcedure(),
        deserialization: @autoclosure @escaping () -> AnyProcedure<Data, Any>
        = AnyDataDeserializationProcedureFactory.empty.dataDeserializationProcedure(),
        interception: @autoclosure @escaping () -> AnyProcedure<Any, Any>
        = AnyInterceptionProcedureFactory.empty.interceptionProcedure(),
        responseMapping: @autoclosure  @escaping () throws -> AnyProcedure<Any, Response>
        ) {
        self.request = request
        self.validation = validation
        self.deserialization = deserialization
        self.interception = interception
        self.responseMapping = responseMapping
    }

    public func requestProcedure() throws -> AnyOutputProcedure<HTTPResponseData> { return try self.request() }
    public func validationProcedure() -> AnyInputProcedure<HTTPResponseData> { return self.validation() }
    public func deserializationProcedure() -> AnyProcedure<Data, Any> { return self.deserialization() }
    public func interceptionProcedure() -> AnyProcedure<Any, Any> { return self.interception() }
    public func responseMappingProcedure() throws -> AnyProcedure<Any, Response> { return try self.responseMapping() }
}

public struct AnyEndpointProcedureComponentsProvider<Response>: EndpointProcedureComponentsProviding {
    private let request: () throws -> AnyOutputProcedure<HTTPResponseData>
    private let validation: () -> AnyInputProcedure<HTTPResponseData>
    private let deserialization: () -> AnyProcedure<Data, Any>
    private let interception: () -> AnyProcedure<Any, Any>
    private let responseMapping: () throws -> AnyProcedure<Any, Response>

    init<U: EndpointProcedureComponentsProviding>(_ wrapped: U) where U.Response == Response {
        self.request = wrapped.requestProcedure
        self.validation = wrapped.validationProcedure
        self.deserialization = wrapped.deserializationProcedure
        self.interception = wrapped.interceptionProcedure
        self.responseMapping = wrapped.responseMappingProcedure
    }

    public func requestProcedure() throws -> AnyOutputProcedure<HTTPResponseData> { return try self.request() }
    public func validationProcedure() -> AnyInputProcedure<HTTPResponseData> { return self.validation() }
    public func deserializationProcedure() -> AnyProcedure<Data, Any> { return self.deserialization() }
    public func interceptionProcedure() -> AnyProcedure<Any, Any> { return self.interception() }
    public func responseMappingProcedure() throws -> AnyProcedure<Any, Response> { return try self.responseMapping() }
}

public struct FactoriesBasedEndpointProcedureConfigurationProvider: EndpointProcedureConfigurationProviding {
    typealias Factories = (
        request: HTTPRequestProcedureFactory,
        validation: ValidationProcedureFactory,
        deserialization: DataDeserializationProcedureFactory,
        interception: InterceptionProcedureFactory,
        responseMapping: ResponseMappingProcedureFactory
    )
    private let factories: Factories
    public init(request: HTTPRequestProcedureFactory,
         validation: ValidationProcedureFactory = AnyValidationProcedureFactory.empty,
         deserialization: DataDeserializationProcedureFactory = AnyDataDeserializationProcedureFactory.empty,
         interception: InterceptionProcedureFactory = AnyInterceptionProcedureFactory.empty,
         responseMapping: ResponseMappingProcedureFactory) {
        self.factories = (request, validation, deserialization, interception, responseMapping)
    }
    
    public func configuration<T>(forRequestData requestData: HTTPRequestData,
                                 responseType: T.Type) -> AnyEndpointProcedureComponentsProvider<T> {
        return ClosureBasedEndpointProcedureComponentsProvider(
            request: try self.factories.request.requestProcedure(with: requestData),
            validation: self.factories.validation.validationProcedure(),
            deserialization: self.factories.deserialization.dataDeserializationProcedure(),
            interception: self.factories.interception.interceptionProcedure(),
            responseMapping: try self.factories.responseMapping.responseMappingProcedure(for: responseType)
            ).wrapped
    }
}
