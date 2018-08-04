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
/// - Loading: load's `HTTPResponseData` from any source.
/// - Validation: validates `HTTPResponseData`
/// - Deserialization: converts loaded `Data` to `Any`
/// - Interception: converst deserialized object to format expected by mapping
/// - Mapping: Converts `Any` to `Result`
///
/// `HTTPDataFlowProcedure` finished after all inner procedure finished.
///

public class HTTPDataFlowProcedure<Result>: DataFlowProcedure<Result>, HTTPURLResponseProcedure {
    ///`HTTPURLResponse` fetched from `dataLoadingProcedure`
    ///
    /// `.pending` if `dataLoadingProcedure` does not contain `HTTPURLResponse`
    public private(set) var urlResponse: Pending<HTTPURLResponse>

    /// Creates `HTTPDataFlowProcedure` with `dataLoadingProcedure`, `validationProcedure`,
    /// `deserializationProcedure`, `interceptionProcedure`, `resultMappingProcedure`
    public init<L: Procedure, V: Procedure, D: Procedure, I: Procedure, M: Procedure>(dataLoadingProcedure: L,
         validationProcedure: V,deserializationProcedure: D, interceptionProcedure: I, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == HTTPResponseData,
        V: InputProcedure, V.Input == HTTPResponseData,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            self.urlResponse = .pending
            let validDataLoadingProcedure = ValidHTTPDataLoadingProcedure(dataLoadingProcedure: dataLoadingProcedure,
                                                                          validationProcedure: validationProcedure)
            super.init(dataLoadingProcedure: validDataLoadingProcedure,
                       deserializationProcedure: deserializationProcedure,
                       interceptionProcedure: interceptionProcedure,
                       resultMappingProcedure: resultMappingProcedure)
            validDataLoadingProcedure.addDidFinishBlockObserver { (procedure, _) in
                self.urlResponse = procedure.urlResponse
            }
    }

    /// Creates `HTTPDataFlowProcedure` with `dataLoadingProcedure`, `deserializationProcedure`,
    /// `interceptionProcedure`, `resultMappingProcedure`
    public convenience override init<L: Procedure, D: Procedure, I: Procedure, M: Procedure>(dataLoadingProcedure: L,
                     deserializationProcedure: D, interceptionProcedure: I, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == HTTPResponseData,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            let validationProcedure = HTTPDataFlowProcedure<Result>.createEmptyValidationProcedure()
            self.init(dataLoadingProcedure: dataLoadingProcedure,
                      validationProcedure: validationProcedure,
                      deserializationProcedure: deserializationProcedure,
                      interceptionProcedure: interceptionProcedure,
                      resultMappingProcedure: resultMappingProcedure)
    }

    /// Creates `HTTPDataFlowProcedure` with `dataLoadingProcedure`, `validationProcedure`,
    /// `deserializationProcedure`, `resultMappingProcedure`.
    ///
    /// Result of `deserializationProcedure` is passed to `resultMappingProcedure`
    public convenience init<L: Procedure, V: Procedure, D: Procedure, M: Procedure>(dataLoadingProcedure: L,
                     validationProcedure: V,deserializationProcedure: D, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == HTTPResponseData,
        V: InputProcedure, V.Input == HTTPResponseData,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            let interceptionProcedure = HTTPDataFlowProcedure<Result>.createEmptyInterceptionProcedure()
            self.init(dataLoadingProcedure: dataLoadingProcedure,
                      validationProcedure: validationProcedure,
                      deserializationProcedure: deserializationProcedure,
                      interceptionProcedure: interceptionProcedure,
                      resultMappingProcedure: resultMappingProcedure)
    }

    /// Creates `HTTPDataFlowProcedure` with `dataLoadingProcedure`,
    /// `deserializationProcedure`, `resultMappingProcedure`.
    ///
    /// Result of `deserializationProcedure` is passed to `resultMappingProcedure`
    public convenience init<L: Procedure, D: Procedure, M: Procedure>(dataLoadingProcedure: L,
                            deserializationProcedure: D, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == HTTPResponseData,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            let validationProcedure = HTTPDataFlowProcedure<Result>.createEmptyValidationProcedure()
            let interceptionProcedure = HTTPDataFlowProcedure<Result>.createEmptyInterceptionProcedure()
            self.init(dataLoadingProcedure: dataLoadingProcedure,
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

    init<L: Procedure, V: Procedure>(dataLoadingProcedure: L, validationProcedure: V) where L: OutputProcedure,
        L.Output == HTTPResponseData, V: InputProcedure, V.Input == HTTPResponseData {
            self.output = .pending
            self.urlResponse = .pending
            let dataExtractingProcedure = TransformProcedure<HTTPResponseData, Data> { return $0.data }
            dataExtractingProcedure.injectResult(from: dataLoadingProcedure)
            validationProcedure.injectResult(from: dataLoadingProcedure)
            dataExtractingProcedure.add(dependency: validationProcedure)
            dataExtractingProcedure.add(condition: NoFailedDependenciesCondition())
            super.init(operations: [dataLoadingProcedure, validationProcedure, dataExtractingProcedure])
            dataExtractingProcedure.addDidFinishBlockObserver { [weak self] (procedure, _) in
                self?.output = procedure.output
            }
            dataLoadingProcedure.addDidFinishBlockObserver { [weak self] (procedure, _) in
                self?.urlResponse = procedure.output.success?.urlResponse.map(Pending.ready) ?? .pending
            }
    }
}
