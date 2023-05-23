//
//  HTTPDataFlowProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
import ProcedureKit

/// `HTTPDataFlowProcedure` manages flow of data from loading from HTTP endpoint to result mapping.
///
/// Data flow:
/// ---------
/// Loading -> Validation -> Deserialization -> Interception -> Mapping
///
/// - Loading: loads `HTTPResponseData` from any source.
/// - Validation: validates `HTTPResponseData`
/// - Deserialization: converts loaded `Data` to `Any`
/// - Interception: converst deserialized object to format expected by mapping
/// - Mapping: Converts `Any` to `Result`
///
/// `HTTPDataFlowProcedure` finished after all inner procedure finished.
///

public class HTTPDataFlowProcedure<Result>: DataFlowProcedure<Result>, HTTPURLResponseProcedure {
    ///`HTTPURLResponse` fetched from `httpDataLoadingProcedure`
    ///
    /// `.pending` if `httpDataLoadingProcedure` does not contain `HTTPURLResponse`
    public private(set) var urlResponse: Pending<HTTPURLResponse>

    /// Creates `HTTPDataFlowProcedure` with `httpDataLoadingProcedure`, `validationProcedure`,
    /// `deserializationProcedure`, `interceptionProcedure`, `resultMappingProcedure`
    public init<L: Procedure, V: Procedure, D: Procedure, I: Procedure, M: Procedure>(httpDataLoadingProcedure: L,
         validationProcedure: V,deserializationProcedure: D, interceptionProcedure: I, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == HTTPResponseData,
        V: InputProcedure, V.Input == HTTPResponseData,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            self.urlResponse = .pending
            let validDataLoadingProcedure = ValidHTTPDataLoadingProcedure(
                httpDataLoadingProcedure: httpDataLoadingProcedure, validationProcedure: validationProcedure
            )
            super.init(dataLoadingProcedure: validDataLoadingProcedure,
                       deserializationProcedure: deserializationProcedure,
                       interceptionProcedure: interceptionProcedure,
                       resultMappingProcedure: resultMappingProcedure)
            validDataLoadingProcedure.addWillFinishBlockObserver { [unowned self] (procedure, _, _) in
                self.urlResponse = procedure.urlResponse
            }
    }

    /// Creates `HTTPDataFlowProcedure` with `httpDataLoadingProcedure`, `deserializationProcedure`,
    /// `interceptionProcedure`, `resultMappingProcedure`
    public convenience init<L: Procedure, D: Procedure, I: Procedure, M: Procedure>(httpDataLoadingProcedure: L,
                     deserializationProcedure: D, interceptionProcedure: I, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == HTTPResponseData,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            let validationProcedure = HTTPDataFlowProcedure<Result>.createEmptyValidationProcedure()
            self.init(httpDataLoadingProcedure: httpDataLoadingProcedure,
                      validationProcedure: validationProcedure,
                      deserializationProcedure: deserializationProcedure,
                      interceptionProcedure: interceptionProcedure,
                      resultMappingProcedure: resultMappingProcedure)
    }

    /// Creates `HTTPDataFlowProcedure` with `httpDataLoadingProcedure`, `validationProcedure`,
    /// `deserializationProcedure`, `resultMappingProcedure`.
    ///
    /// Result of `deserializationProcedure` is passed to `resultMappingProcedure`
    public convenience init<L: Procedure, V: Procedure, D: Procedure, M: Procedure>(httpDataLoadingProcedure: L,
                     validationProcedure: V,deserializationProcedure: D, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == HTTPResponseData,
        V: InputProcedure, V.Input == HTTPResponseData,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            let interceptionProcedure = HTTPDataFlowProcedure<Result>.createEmptyInterceptionProcedure()
            self.init(httpDataLoadingProcedure: httpDataLoadingProcedure,
                      validationProcedure: validationProcedure,
                      deserializationProcedure: deserializationProcedure,
                      interceptionProcedure: interceptionProcedure,
                      resultMappingProcedure: resultMappingProcedure)
    }

    /// Creates `HTTPDataFlowProcedure` with `httpDataLoadingProcedure`,
    /// `deserializationProcedure`, `resultMappingProcedure`.
    ///
    /// Result of `deserializationProcedure` is passed to `resultMappingProcedure`
    public convenience init<L: Procedure, D: Procedure, M: Procedure>(httpDataLoadingProcedure: L,
                            deserializationProcedure: D, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == HTTPResponseData,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            let validationProcedure = HTTPDataFlowProcedure<Result>.createEmptyValidationProcedure()
            let interceptionProcedure = HTTPDataFlowProcedure<Result>.createEmptyInterceptionProcedure()
            self.init(httpDataLoadingProcedure: httpDataLoadingProcedure,
                      validationProcedure: validationProcedure,
                      deserializationProcedure: deserializationProcedure,
                      interceptionProcedure: interceptionProcedure,
                      resultMappingProcedure: resultMappingProcedure)
    }
}

extension HTTPDataFlowProcedure {
    /// - returns: Validation procedure that always finishes without errors
    static func createEmptyValidationProcedure() -> TransformProcedure<HTTPResponseData, Void> {
        return TransformProcedure {_ in}
    }
}

fileprivate class ValidHTTPDataLoadingProcedure: GroupProcedure, OutputProcedure {

    var output: Pending<ProcedureResult<Data>>
    var urlResponse: Pending<HTTPURLResponse>

    init<L: Procedure, V: Procedure>(httpDataLoadingProcedure: L, validationProcedure: V) where L: OutputProcedure,
        L.Output == HTTPResponseData, V: InputProcedure, V.Input == HTTPResponseData {
            self.output = .pending
            self.urlResponse = .pending
            let dataExtractingProcedure = TransformProcedure<HTTPResponseData, Data> { return $0.data }
            dataExtractingProcedure.injectResult(from: httpDataLoadingProcedure)
            validationProcedure.injectResult(from: httpDataLoadingProcedure)
            dataExtractingProcedure.addDependency(validationProcedure)
            dataExtractingProcedure.addCondition(NoFailedDependenciesCondition())
            super.init(operations: [httpDataLoadingProcedure, validationProcedure, dataExtractingProcedure])
            dataExtractingProcedure.addWillFinishBlockObserver { [unowned self] (procedure, _, _) in
                self.output = procedure.output
            }
            httpDataLoadingProcedure.addWillFinishBlockObserver { [unowned self] (procedure, _, _) in
                self.urlResponse = procedure.output.success?.urlResponse.map(Pending.ready) ?? .pending
            }
    }
}
