//
//  EndpointProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

public enum EndpointProcedureError: Error {
    case missingConfiguration
    case pendingOutputAfterCompletion
}

private enum EndpointProcedureInitialization<Result> {
    case error(Error)
    case dataFlowProcedure(DataFlowProcedure<Result>)
}

open class EndpointProcedure<Result>: GroupProcedure, OutputProcedure {
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

    public init(dataFlowProcedure: DataFlowProcedure<Result>) {
        self.initialization = .dataFlowProcedure(dataFlowProcedure)
        super.init(operations: [dataFlowProcedure])
    }

    public init<V: Procedure, I: Procedure>(requestData: HTTPRequestData,
         validationProcedure: V, interceptionProcedure: I, configuration: ConfigurationProtocol! = nil)
        where V: InputProcedure, V.Input == HTTPResponseData,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any {
            do {
                let dataFlowProcedure = try EndpointProcedure<Result>
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

    public init<L: Procedure, I: Procedure>(dataLoadingProcedure: L, interceptionProcedure: I,
                     configuration: ConfigurationProtocol! = nil) where L: OutputProcedure, L.Output == Data,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any {
            do {
                let dataFlowProcedure = try EndpointProcedure<Result>.dataFlowProcedure(with: configuration,
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
            guard let configuration = configuration ?? Configuration.default else {
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
            guard let configuration = configuration ?? Configuration.default else {
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
}

extension EndpointProcedure {

    public convenience init<V: Procedure>(requestData: HTTPRequestData, validationProcedure: V, configuration: ConfigurationProtocol! = nil)
        where V: InputProcedure, V.Input == HTTPResponseData {
            let interceptionProcedure = HTTPDataFlowProcedure<Result>.createEmptyInterceptionProcedure()
            self.init(requestData: requestData, validationProcedure: validationProcedure,
                      interceptionProcedure: interceptionProcedure, configuration: configuration)
    }

    public convenience init<I: Procedure>(requestData: HTTPRequestData, interceptionProcedure: I, configuration: ConfigurationProtocol! = nil)
        where I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any {
            let validationProcedure = HTTPDataFlowProcedure<Result>.createEmptyValidationProcedure()
            self.init(requestData: requestData, validationProcedure: validationProcedure,
                      interceptionProcedure: interceptionProcedure, configuration: configuration)
    }

    public convenience init(requestData: HTTPRequestData, configuration: ConfigurationProtocol! = nil) {
        let validationProcedure = HTTPDataFlowProcedure<Result>.createEmptyValidationProcedure()
        let interceptionProcedure = HTTPDataFlowProcedure<Result>.createEmptyInterceptionProcedure()
        self.init(requestData: requestData, validationProcedure: validationProcedure,
                  interceptionProcedure: interceptionProcedure, configuration: configuration)
    }
}

extension EndpointProcedure {

    public convenience init<L: Procedure>(dataLoadingProcedure: L, configuration: ConfigurationProtocol! = nil)
                    where L: OutputProcedure, L.Output == Data {
        let interceptionProcedure = DataFlowProcedure<Result>.createEmptyInterceptionProcedure()
        self.init(dataLoadingProcedure: dataLoadingProcedure, interceptionProcedure: interceptionProcedure,
                  configuration: configuration)
    }
}
