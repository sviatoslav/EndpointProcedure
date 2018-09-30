//
//  EndpointProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

/// Errors that `EndpointProcedure` can return in `output` property.
public enum EndpointProcedureError: Error {
    /// `EndpointProcedure` was initialized without `configuration`.
    ///
    /// How to fix
    /// ----------
    /// Pass `configuration` in `EndpointProcedure` initializer
    /// or set value for `Configuration.default` property.
    case missingConfiguration
    ///`output` was not ready after procedure completion.
    case pendingOutputAfterCompletion
}

///Internal type that is used for `EndpointProcedure` initialization.
private enum EndpointProcedureInitialization<Result> {
    /// `error` occured during `EndpointProcedure` initialization.
    case error(Error)
    /// Succesfull initialization
    case dataFlowProcedure(DataFlowProcedure<Result>)
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
public class EndpointProcedure<Result>: GroupProcedure, OutputProcedure {
    /// Result of `EndpointProcedure`.
    /// Do not set this value from code. Changes will not be applied.
    public var output: Pending<ProcedureResult<Result>> {
        get {
            switch self.initialization {
            case .error(let error): return .ready(.failure(error))
            case .dataFlowProcedure(let dataFlowProcedure):
                if self.isFinished, case .pending = dataFlowProcedure.output {
                    return .ready(.failure(EndpointProcedureError.pendingOutputAfterCompletion))
                }
                return dataFlowProcedure.output
            }
        }
        //READ-ONLY
        set {}
    }

    private let initialization: EndpointProcedureInitialization<Result>

    public init(error: Error) {
        self.initialization = .error(error)
        super.init(operations: [])
    }

    /// Creates `EndpointProcedure` with `DataFlowProcedure` inside regardless any `Configuration` value.
    ///
    /// - Parameter dataFlowProcedure: procedure that should be run inside `EnpointProcedure`
    public init(dataFlowProcedure: DataFlowProcedure<Result>) {
        self.initialization = .dataFlowProcedure(dataFlowProcedure)
        super.init(operations: [dataFlowProcedure])
    }

    /// Creates `EndpointProcedure` connecting with HTTP endpoint.
    /// 
    /// - Parameters:
    ///   - requestData: specifies attributes of HTTP request.
    ///   - validationProcedure: receives `HTTPResponseData` as an input.
    /// Stops `EndpointProcedure`, if finishes with errors.
    ///   - interceptionProcedure: receives deserialized response data as an input.
    /// Should transform input to a format expected by `mappingProcedure`.
    /// Stops `EndpointProcedure`, if finishes with errors.
    ///   - configuration: determines what `dataLoadingProcedureFactory`, `dataDeserializationProcedureFactory`
    /// and `responseMappingProcedureFactory` should be used for coresponding procedures creation.
    /// `Configuration.default` used if no value passed.
    /// If no value passed and `Configuration.default` is not initialize, 
    /// `EndpointProcedure` will finish with `EndpointProcedureError.missingConfiguration
    ///
    public init<V: Procedure, I: Procedure>(requestData: HTTPRequestData,
         validationProcedure: V, interceptionProcedure: I, configuration: ConfigurationProtocol! = nil)
        where V: InputProcedure, V.Input == HTTPResponseData,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any {
            do {
                let dataFlowProcedure = try type(of: self)
                    .dataFlowProcedure(with: configuration, requestData: requestData,
                                       validationProcedure: validationProcedure,
                                       interceptionProcedure: interceptionProcedure)
                self.initialization = .dataFlowProcedure(dataFlowProcedure)
                super.init(operations: [dataFlowProcedure])
            } catch let error {
                self.initialization = .error(error)
                super.init(operations: [])
            }
    }

    /// Creates `EndpointProcedure` connecting with enpoint specified in `dataLoadingProcedure`.
    /// Can be used for connecting to local endpoits.
    ///
    /// - Parameters:
    ///   - dataLoadingProcedure: specifies connection to data endpoint.
    ///   - interceptionProcedure: receives deserialized response data as an input.
    /// Should transform input to a format expected by `mappingProcedure`.
    /// Stops `EndpointProcedure`, if finishes with errors.
    ///   - configuration: determines what `dataDeserializationProcedureFactory`
    /// and `responseMappingProcedureFactory` should be used for coresponding procedures creation.
    /// `Configuration.default` used if no value passed.
    /// If no value passed and `Configuration.default` is not initialize,
    /// `EndpointProcedure` will finish with `EndpointProcedureError.missingConfiguration
    ///
    public init<L: Procedure, I: Procedure>(dataLoadingProcedure: L, interceptionProcedure: I,
                     configuration: ConfigurationProtocol! = nil) where L: OutputProcedure, L.Output == Data,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any {
            do {
                let dataFlowProcedure = try type(of: self).dataFlowProcedure(with: configuration,
                                                                        dataLoadingProcedure: dataLoadingProcedure,
                                                                        interceptionProcedure: interceptionProcedure)
                self.initialization = .dataFlowProcedure(dataFlowProcedure)
                super.init(operations: [dataFlowProcedure])
            } catch let error {
                self.initialization = .error(error)
                super.init(operations: [])
            }
    }

    private static func dataFlowProcedure<V: Procedure, I: Procedure>(with configuration: ConfigurationProtocol!,
                                          requestData: HTTPRequestData, validationProcedure: V,
                                          interceptionProcedure: I) throws -> DataFlowProcedure<Result>
        where V: InputProcedure, V.Input == HTTPResponseData,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any {
            guard let configuration = configuration ?? self.defaultConfiguration else {
                throw EndpointProcedureError.missingConfiguration
            }
            let dataLoadingProcedure = try configuration.dataLoadingProcedureFactory
                .dataLoadingProcedure(with: requestData)
            let deserializationProcedure = configuration.dataDeserializationProcedureFactory
                .dataDeserializationProcedure()
            let mappingProcedure = try configuration.responseMappingProcedureFactory
                .responseMappingProcedure(for: Result.self)
            return HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedure,
                                         validationProcedure: validationProcedure,
                                         deserializationProcedure: deserializationProcedure,
                                         interceptionProcedure: interceptionProcedure,
                                         resultMappingProcedure: mappingProcedure)
    }

    private static func dataFlowProcedure<L: Procedure, I: Procedure>(with configuration: ConfigurationProtocol!,
                                  dataLoadingProcedure: L, interceptionProcedure: I) throws -> DataFlowProcedure<Result>
        where L: OutputProcedure, L.Output == Data,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any {
            guard let configuration = configuration ?? self.defaultConfiguration else {
                throw EndpointProcedureError.missingConfiguration
            }
            let deserializationProcedure = configuration.dataDeserializationProcedureFactory
                .dataDeserializationProcedure()
            let mappingProcedure = try configuration.responseMappingProcedureFactory
                .responseMappingProcedure(for: Result.self)
            return DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedure,
                                     deserializationProcedure: deserializationProcedure,
                                     interceptionProcedure: interceptionProcedure,
                                     resultMappingProcedure: mappingProcedure)
    }

    open class var defaultConfiguration: ConfigurationProtocol? {
        return Configuration.default
    }
}

extension EndpointProcedure {

    /// Creates `EndpointProcedure` connecting with HTTP endpoint.
    ///
    /// - Parameters:
    ///   - requestData: specifies attributes of HTTP request.
    ///   - validationProcedure: receives `HTTPResponseData` as an input.
    /// Stops `EndpointProcedure`, if finishes with errors.
    ///   - configuration: determines what `dataLoadingProcedureFactory`, `dataDeserializationProcedureFactory`
    /// and `responseMappingProcedureFactory` should be used for coresponding procedures creation.
    /// `Configuration.default` used if no value passed.
    /// If no value passed and `Configuration.default` is not initialize,
    /// `EndpointProcedure` will finish with `EndpointProcedureError.missingConfiguration
    ///
    public convenience init<V: Procedure>(requestData: HTTPRequestData, validationProcedure: V,
                            configuration: ConfigurationProtocol! = nil)
        where V: InputProcedure, V.Input == HTTPResponseData {
            let interceptionProcedure = HTTPDataFlowProcedure<Result>.createEmptyInterceptionProcedure()
            self.init(requestData: requestData, validationProcedure: validationProcedure,
                      interceptionProcedure: interceptionProcedure, configuration: configuration)
    }

    /// Creates `EndpointProcedure` connecting with HTTP endpoint.
    ///
    /// - Parameters:
    ///   - requestData: specifies attributes of HTTP request.
    ///   - interceptionProcedure: receives deserialized response data as an input.
    /// Should transform input to a format expected by `mappingProcedure`.
    /// Stops `EndpointProcedure`, if finishes with errors.
    ///   - configuration: determines what `dataLoadingProcedureFactory`, `dataDeserializationProcedureFactory`
    /// and `responseMappingProcedureFactory` should be used for coresponding procedures creation.
    /// `Configuration.default` used if no value passed.
    /// If no value passed and `Configuration.default` is not initialize,
    /// `EndpointProcedure` will finish with `EndpointProcedureError.missingConfiguration
    ///
    public convenience init<I: Procedure>(requestData: HTTPRequestData, interceptionProcedure: I,
                            configuration: ConfigurationProtocol! = nil)
        where I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any {
            let validationProcedure = HTTPDataFlowProcedure<Result>.createEmptyValidationProcedure()
            self.init(requestData: requestData, validationProcedure: validationProcedure,
                      interceptionProcedure: interceptionProcedure, configuration: configuration)
    }

    /// Creates `EndpointProcedure` connecting with HTTP endpoint.
    ///
    /// - Parameters:
    ///   - requestData: specifies attributes of HTTP request.
    ///   - configuration: determines what `dataLoadingProcedureFactory`, `dataDeserializationProcedureFactory`
    /// and `responseMappingProcedureFactory` should be used for coresponding procedures creation.
    /// `Configuration.default` used if no value passed.
    /// If no value passed and `Configuration.default` is not initialize,
    /// `EndpointProcedure` will finish with `EndpointProcedureError.missingConfiguration
    ///
    public convenience init(requestData: HTTPRequestData, configuration: ConfigurationProtocol! = nil) {
        let validationProcedure = HTTPDataFlowProcedure<Result>.createEmptyValidationProcedure()
        let interceptionProcedure = HTTPDataFlowProcedure<Result>.createEmptyInterceptionProcedure()
        self.init(requestData: requestData, validationProcedure: validationProcedure,
                  interceptionProcedure: interceptionProcedure, configuration: configuration)
    }
}

extension EndpointProcedure {

    /// Creates `EndpointProcedure` connecting with enpoint specified in `dataLoadingProcedure`.
    /// Can be used for connecting to local endpoits.
    ///
    /// - Parameters:
    ///   - dataLoadingProcedure: specifies connection to data endpoint.
    ///   - configuration: determines what `dataDeserializationProcedureFactory`
    /// and `responseMappingProcedureFactory` should be used for coresponding procedures creation.
    /// `Configuration.default` used if no value passed.
    /// If no value passed and `Configuration.default` is not initialize,
    /// `EndpointProcedure` will finish with `EndpointProcedureError.missingConfiguration
    ///
    public convenience init<L: Procedure>(dataLoadingProcedure: L, configuration: ConfigurationProtocol! = nil)
                    where L: OutputProcedure, L.Output == Data {
        let interceptionProcedure = DataFlowProcedure<Result>.createEmptyInterceptionProcedure()
        self.init(dataLoadingProcedure: dataLoadingProcedure, interceptionProcedure: interceptionProcedure,
                  configuration: configuration)
    }
}
