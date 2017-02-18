//
//  HTTPDataFlowProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
import ProcedureKit

public class HTTPDataFlowProcedure<Result>: DataFlowProcedure<Result>, HTTPURLResponseProcedure {
    public private(set) var urlResponse: Pending<HTTPURLResponse>

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
            validDataLoadingProcedure.addDidFinishBlockObserver {
                self.urlResponse = $0.0.urlResponse
            }
    }

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

    public convenience init<L: Procedure, D: Procedure, M: Procedure>(dataLoadingProcedure: L, deserializationProcedure: D,
                     resultMappingProcedure: M) where L: OutputProcedure, L.Output == HTTPResponseData,
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
            dataExtractingProcedure.addDidFinishBlockObserver { [weak self] in
                self?.output = $0.0.output
            }
            dataLoadingProcedure.addDidFinishBlockObserver { [weak self] in
                self?.urlResponse = $0.0.output.success?.urlResponse.map(Pending.ready) ?? .pending
            }
    }
}
