//
//  DataFlowProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

open class DataFlowProcedure<Result>: GroupProcedure, OutputProcedure {
    public var output: Pending<ProcedureResult<Result>>

    public init<L: Procedure, D: Procedure, I: Procedure, M: Procedure>(dataLoadingProcedure: L, deserializationProcedure: D, interceptionProcedure: I, resultMappingProcedure: M) where L: OutputProcedure, L.Output == Data,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            self.output = .pending
            deserializationProcedure.injectResult(from: dataLoadingProcedure)
            interceptionProcedure.injectResult(from: deserializationProcedure)
            resultMappingProcedure.injectResult(from: interceptionProcedure)
            let children: [Procedure] = [dataLoadingProcedure, deserializationProcedure, interceptionProcedure,
                                         resultMappingProcedure]
            children.forEach { $0.add(condition: NoFailedDependenciesCondition()) }
            super.init(operations: children)
            resultMappingProcedure.addDidFinishBlockObserver { [weak self] in
                self?.output = $0.0.output
            }
    }

    public convenience init<L: Procedure, D: Procedure, M: Procedure>(dataLoadingProcedure: L, deserializationProcedure: D,
                     resultMappingProcedure: M) where L: OutputProcedure, L.Output == Data,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            self.init(dataLoadingProcedure: dataLoadingProcedure, deserializationProcedure: deserializationProcedure,
                      interceptionProcedure: DataFlowProcedure<Result>.createEmptyInterceptionProcedure(),
                      resultMappingProcedure: resultMappingProcedure)
    }

    static func createEmptyInterceptionProcedure() -> TransformProcedure<Any, Any> {
        return TransformProcedure {$0}
    }

    final public override func procedureDidFinish(withErrors: [Error]) {
        guard case .pending = self.output, let error = withErrors.first else {
            return
        }
        let contexts: [ProcedureKitError.Context] = [.parentCancelledWithErrors, .dependencyFinishedWithErrors]
        if let procedureKitError = error as? ProcedureKitError, contexts.contains(procedureKitError.context) {
            self.procedureDidFinish(withErrors: procedureKitError.errors)
        } else {
            self.output = .ready(.failure(error))
        }
    }
}
