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
/// It's highly recommended to set `Configuration.default` and `HTTPRequestData.Builder.baseURL`
/// before creating any `EndpointProcedure`
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
open class EndpointProcedure<Result>: GroupProcedure, OutputProcedure {
    /// Result of `EndpointProcedure`.
    public var output: Pending<ProcedureResult<Result>> = .pending

    private var embedDataFlowProcedure: DataFlowProcedure<Result>? = nil

    public init() {
        super.init(operations: [])
    }

    open func dataLoadingProcedure() throws -> AnyOutputProcedure<Data> {
        throw EndpointProcedureError.Internal.unimplementedDataLoadingProcedure
    }
    open func httpDataLoadingProcedure() throws -> AnyOutputProcedure<HTTPResponseData> {
        guard let provider = self as? ConfigurationProviding & HTTPRequestDataProviding else {
            throw EndpointProcedureError.missingDataLoadingProcedure
        }
        return try provider.configuration.dataLoadingProcedureFactory.dataLoadingProcedure(with: provider.requestData())
    }
    open func validationProcedure() -> AnyInputProcedure<HTTPResponseData> {
        return AnyInputProcedure(TransformProcedure<HTTPResponseData, Void> {_ in})
    }
    open func deserializationProcedure() -> AnyProcedure<Data, Any> {
        guard let configurationProvider = self as? ConfigurationProviding else {
            return AnyProcedure(TransformProcedure { $0 })
        }
        return configurationProvider.configuration.dataDeserializationProcedureFactory.dataDeserializationProcedure()
    }
    open func interceptionProcedure() -> AnyProcedure<Any, Any> {
        return AnyProcedure(TransformProcedure { $0 })
    }
    open func mappingProcedure() throws -> AnyProcedure<Any, Result> {
        guard let configurationProvider = self as? ConfigurationProviding else {
            throw EndpointProcedureError.missingMappingProcedure
        }
        return try configurationProvider.configuration.responseMappingProcedureFactory
            .responseMappingProcedure(for: Result.self)
    }

    open func dataFlowProcedure() throws -> DataFlowProcedure<Result> {
        let dataLoading: AnyOutputProcedure<Data>?
        do {
            dataLoading = try self.dataLoadingProcedure()
        } catch EndpointProcedureError.Internal.unimplementedDataLoadingProcedure {
            dataLoading = nil
        }
        return try dataLoading.map({
            DataFlowProcedure(dataLoadingProcedure: $0, deserializationProcedure: self.deserializationProcedure(),
                              interceptionProcedure: self.interceptionProcedure(), resultMappingProcedure: try self.mappingProcedure())
        }) ?? HTTPDataFlowProcedure(dataLoadingProcedure: self.httpDataLoadingProcedure(),
                                    validationProcedure: self.validationProcedure(),
                                    deserializationProcedure: self.deserializationProcedure(),
                                    interceptionProcedure: self.interceptionProcedure(),
                                    resultMappingProcedure: try self.mappingProcedure())
    }

    open override func execute() {
        do {
            let procedure = try self.dataFlowProcedure()
            self.embedDataFlowProcedure = procedure
            procedure.addDidFinishBlockObserver { [weak self] (procedure, _) in
                self?.output = procedure.output
            }
            self.add(child: procedure)
        } catch let error {
            self.output = .ready(.failure(error))
        }
        super.execute()
    }
}

protocol ConfigurationProviding {
    var configuration: ConfigurationProtocol { get }
}

protocol HTTPRequestDataProviding {
    func requestData() throws -> HTTPRequestData
}
