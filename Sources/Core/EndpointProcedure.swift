//
//  EndpointProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif

/// Errors that `EndpointProcedure` can return in `output` property.
public enum EndpointProcedureError: Error {
    case missingDataLoadingProcedure
    case missingMappingProcedure

    fileprivate enum Internal: Error {
        case unimplementedDataLoadingProcedure
    }
}

/// `EndpointProcedure` wraps `DataFlowProcedure` and is aimed for easy creation connections with endpoints.
///
/// Examples
/// --------
/// Creating simplest `EndpointProcedure`:
///
///     let requestData = HTTPRequestData.Builder.for(path: "users").build()
///     let usersProcedure = EndpointProcedure<[User]>(requestData: requestData)
///
/// Using `validationProcedure`:
///
///     let validation = TransformProcedure<HTTPResponseData, Void> {
///         if $0.urlResponse?.statusCode >= 400 {
///             throw Error.invalidStatusCode
///         }
///     }
///     let requestData = HTTPRequestData.Builder.for(path: "users").build()
///     let usersProcedure = EndpointProcedure<[User]>(requestData: requestData, validationProcedure: validation)
///
/// Using `interceptionProcedure`:
///
///     let interception = TransformProcedure<Any, Any> {
///         guard let dataDictionary = $0 as? [AnyHashable: Any] else {
///             throw Error.invalidResponseFormat
///         }
///         guard let usersArray = dataDictionary["data"] as? [Any] else {
///             throw Error.invalidResponseFormat
///         }
///         return usersArray
///     }
///     let requestData = HTTPRequestData.Builder.for(path: "users").build()
///     let usersProcedure = EndpointProcedure<[User]>(requestData: requestData, interceptionProcedure: interception)
///
/// Using custom `configuration`:
///
///     let configuration = //initialize with appropriate procedure factories
///     let requestData = HTTPRequestData.Builder.for(path: "users").build()
///     let usersProcedure = EndpointProcedure<[User]>(requestData: requestData, configuration: configuration)
///
/// Using custom `dataLoadingProcedure`:
///
///     let url = //Any URL
///     let dataLoadingProcedure = ContentsOfURLLoadingProcedure(url: url)
///     let usersProcedure = EndpointProcedure<[User]>(dataLoadingProcedure: dataLoadingProcedure)
///
open class EndpointProcedure<Result>: GroupProcedure, OutputProcedure, EndpointProcedureComponentsProviding {

    /// Result of `EndpointProcedure`.
    public var output: Pending<ProcedureResult<Result>> = .pending
    private var configurationStorage: AnyEndpointProcedureComponentsProvider<Result>? = nil
    public var configuration: AnyEndpointProcedureComponentsProvider<Result> {
        get {
            if let storage = self.configurationStorage { return storage }
            do {
                guard let container = (self as? ConfigurationProviderContaining & HTTPRequestDataContaining) else {
                    throw EndpointProcedureError.missingDataLoadingProcedure
                }
                return try container.configurationProvider.configuration(forRequestData: container.requestData(),
                                                                         responseType: Result.self)
            } catch let error {
                return DefaultConfiguration(requestProcedureError: error).wrapped
            }
        }
        set {
            self.configurationStorage = newValue
        }
    }
    public init() {
        super.init(operations: [])
    }
    open func dataLoadingProcedure() throws -> AnyOutputProcedure<Data> {
        throw EndpointProcedureError.Internal.unimplementedDataLoadingProcedure
    }
    open func requestProcedure() throws -> AnyOutputProcedure<HTTPResponseData> {
        return try self.configuration.requestProcedure()
    }
    open func validationProcedure() -> AnyInputProcedure<HTTPResponseData> {
        return self.configuration.validationProcedure()
    }
    open func deserializationProcedure() -> AnyProcedure<Data, Any> {
        return self.configuration.deserializationProcedure()
    }
    open func interceptionProcedure() -> AnyProcedure<Any, Any> {
        return self.configuration.interceptionProcedure()
    }
    open func responseMappingProcedure() throws -> AnyProcedure<Any, Result> {
        return try self.configuration.responseMappingProcedure()
    }
    open func dataFlowProcedure() throws -> DataFlowProcedure<Result> {
        let dataLoading: AnyOutputProcedure<Data>?
        do {
            dataLoading = try self.dataLoadingProcedure()
        } catch EndpointProcedureError.Internal.unimplementedDataLoadingProcedure {
            dataLoading = nil
        }
        return try dataLoading.map({
            DataFlowProcedure(dataLoadingProcedure: $0,
                              deserializationProcedure: self.deserializationProcedure(),
                              interceptionProcedure: self.interceptionProcedure(),
                              resultMappingProcedure: try self.responseMappingProcedure())
        }) ?? HTTPDataFlowProcedure(dataLoadingProcedure: self.requestProcedure(),
                                    validationProcedure: self.validationProcedure(),
                                    deserializationProcedure: self.deserializationProcedure(),
                                    interceptionProcedure: self.interceptionProcedure(),
                                    resultMappingProcedure: try self.responseMappingProcedure())
    }
    open override func execute() {
        do {
            let procedure = try self.dataFlowProcedure()
            procedure.addDidFinishBlockObserver { [weak self] (procedure, _) in
                self?.output = procedure.output
            }
            self.addChild(procedure)
        } catch let error {
            self.output = .ready(.failure(error))
        }
        super.execute()
    }
}

private struct DefaultConfiguration<Response>: EndpointProcedureComponentsProviding {
    private let requestProcedureError: Error
    init(requestProcedureError: Error = EndpointProcedureError.missingDataLoadingProcedure) {
        self.requestProcedureError = requestProcedureError
    }
    func requestProcedure() throws -> AnyOutputProcedure<HTTPResponseData> {
        throw self.requestProcedureError
    }
    func responseMappingProcedure() throws -> AnyProcedure<Any, Response> {
        throw EndpointProcedureError.missingMappingProcedure
    }
}

protocol ConfigurationProviderContaining {
    var configurationProvider: EndpointProcedureConfigurationProviding { get }
}

protocol HTTPRequestDataContaining {
    func requestData() throws -> HTTPRequestData
}
