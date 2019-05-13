//
//  DataFlowProcedureBuilder.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/23/19.
//

import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif

public struct DataFlowProcedureBuilder: ValidationProcedureBuilding {
    private let loading: Loading
    private var validation = AnyValidationProcedureFactory.empty.validationProcedure()
    private var deserialization = AnyDataDeserializationProcedureFactory.empty.dataDeserializationProcedure()
    private var interception = AnyInterceptionProcedureFactory.empty.interceptionProcedure()

    private init(loading: Loading) {
        self.loading = loading
    }

    public static func load<T: Procedure>(using procedure: T) -> DeserializationProcedureBuilding
        where T: OutputProcedure, T.Output == Data {
            return DataFlowProcedureBuilder(loading: .data(AnyOutputProcedure(procedure)))
    }
    public static func load<T: Procedure>(using procedure: T) -> ValidationProcedureBuilding
        where T: OutputProcedure, T.Output == HTTPResponseData {
            return DataFlowProcedureBuilder(loading: .httpData(AnyOutputProcedure(procedure)))
    }

    public func validate<T: Procedure>(using procedure: T) -> DeserializationProcedureBuilding
        where T: InputProcedure, T.Input == HTTPResponseData {
            return self.mutate(using: { $0.validation = AnyInputProcedure(procedure) })
    }
    public func deserialize<T: Procedure>(using procedure: T) -> InterceptionProcedureBuilding
        where T: InputProcedure & OutputProcedure, T.Input == Data, T.Output == Any {
            return self.mutate(using: { $0.deserialization = AnyProcedure(procedure) })
    }
    public func intercept<T: Procedure>(using procedure: T) -> MappingProcedureBuilding
        where T: InputProcedure & OutputProcedure, T.Input == Any, T.Output == Any {
            return self.mutate(using: { $0.interception = AnyProcedure(procedure) })
    }
    public func map<T: Procedure>(using procedure: T) -> DataFlowProcedure<T.Output>
        where T: InputProcedure & OutputProcedure, T.Input == Any {
            switch self.loading {
            case .data(let loading): return DataFlowProcedure(dataLoadingProcedure: loading,
                                                              deserializationProcedure: self.deserialization,
                                                              interceptionProcedure: self.interception,
                                                              resultMappingProcedure: procedure)
            case .httpData(let loading): return HTTPDataFlowProcedure(dataLoadingProcedure: loading,
                                                                      validationProcedure: self.validation,
                                                                      deserializationProcedure: self.deserialization,
                                                                      interceptionProcedure: self.interception,
                                                                      resultMappingProcedure: procedure)
            }
    }

    private func mutate(using mutator: (inout DataFlowProcedureBuilder) -> Void) -> DataFlowProcedureBuilder {
        var mutable = self
        mutator(&mutable)
        return mutable
    }
}

public protocol ValidationProcedureBuilding: DeserializationProcedureBuilding {
    func validate<T: Procedure>(using procedure: T) -> DeserializationProcedureBuilding
        where T: InputProcedure, T.Input == HTTPResponseData
}

public protocol DeserializationProcedureBuilding: InterceptionProcedureBuilding {
    func deserialize<T: Procedure>(using procedure: T) -> InterceptionProcedureBuilding
        where T: InputProcedure & OutputProcedure, T.Input == Data, T.Output == Any
}

public protocol InterceptionProcedureBuilding: MappingProcedureBuilding {
    func intercept<T: Procedure>(using procedure: T) -> MappingProcedureBuilding
        where T: InputProcedure & OutputProcedure, T.Input == Any, T.Output == Any
}

public protocol MappingProcedureBuilding {
    func map<T: Procedure>(using procedure: T) -> DataFlowProcedure<T.Output>
        where T: InputProcedure & OutputProcedure, T.Input == Any
}

extension DataFlowProcedureBuilder {
    fileprivate enum Loading {
        case data(AnyOutputProcedure<Data>)
        case httpData(AnyOutputProcedure<HTTPResponseData>)
    }
}
