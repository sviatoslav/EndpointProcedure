//
//  DataFlowProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
import ProcedureKit

/// `DataFlowProcedure` manages flow of data from loading to result mapping.
///
/// Data flow:
/// ---------
/// Loading -> Deserialization -> Interception -> Mapping
///
/// - Loading: load's `Data` from any source.
/// - Deserialization: converts loaded `Data` to `Any`
/// - Interception: converst deserialized object to format expected by mapping
/// - Mapping: Converst `Any` to `Result`
///
/// `DataFlowProcedure` finished after all inner procedure finished.
///
open class DataFlowProcedure<Result>: GroupProcedure, OutputProcedure {
    /// Result of `DataFlowProcedure`.
    ///
    /// Injected from `resultMappingProcedure`
    public var output: Pending<ProcedureResult<Result>>

    /// Creates `DataFlowProcedure` with `dataLoadingProcedure`, `deserializationProcedure`,
    /// `interceptionProcedure`, `resultMappingProcedure`
    public init<L: Procedure, D: Procedure, I: Procedure, M: Procedure>(dataLoadingProcedure: L,
                deserializationProcedure: D, interceptionProcedure: I, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == Data,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        I: InputProcedure & OutputProcedure, I.Input == Any, I.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            self.output = .pending
            deserializationProcedure.injectResult(from: dataLoadingProcedure)
            interceptionProcedure.injectResult(from: deserializationProcedure)
            resultMappingProcedure.injectResult(from: interceptionProcedure)
            let children: [Procedure] = [dataLoadingProcedure, deserializationProcedure, interceptionProcedure,
                                         resultMappingProcedure]
            children.forEach { $0.addCondition(NoFailedDependenciesCondition()) }
            super.init(operations: children)
            resultMappingProcedure.addWillFinishBlockObserver { [weak self] (procedure, _, _) in
                self?.output = procedure.output
            }
    }

    /// Creates `DataFlowProcedure` with `dataLoadingProcedure`, `deserializationProcedure`, `resultMappingProcedure`.
    ///
    /// Result of `deserializationProcedure` is passed to `resultMappingProcedure`
    public convenience init<L: Procedure, D: Procedure, M: Procedure>(dataLoadingProcedure: L,
                            deserializationProcedure: D, resultMappingProcedure: M)
        where L: OutputProcedure, L.Output == Data,
        D: InputProcedure & OutputProcedure, D.Input == Data, D.Output == Any,
        M: InputProcedure & OutputProcedure, M.Input == Any, M.Output == Result {
            self.init(dataLoadingProcedure: dataLoadingProcedure, deserializationProcedure: deserializationProcedure,
                      interceptionProcedure: DataFlowProcedure<Result>.createEmptyInterceptionProcedure(),
                      resultMappingProcedure: resultMappingProcedure)
    }

    /// Processes errors sets correct error as `output`
    final public override func procedureDidFinish(with error: Error?) {
        guard case .pending = self.output, let error = error else {
            return
        }
        let contexts: [ProcedureKitError.Context] = [.parentCancelledWithError, .dependencyFinishedWithError]
        if let procedureKitError = error as? ProcedureKitError, contexts.contains(procedureKitError.context) {
            self.procedureDidFinish(with: procedureKitError.error)
        } else {
            self.output = .ready(.failure(error))
        }
    }
}

extension DataFlowProcedure {
    /// - returns: Interception procedure that does not change input value
    static func createEmptyInterceptionProcedure() -> TransformProcedure<Any, Any> {
        return TransformProcedure {$0}
    }
}
