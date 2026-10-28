//
//  DataFlowProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import Foundation
import ProcedureKit
@testable import EndpointProcedure

class DataFlowProcedureTests: XCTestCase {

    private enum Error: Int, Swift.Error {
        case dataLoading
        case deserialization
        case intercepting
        case mapping
    }

    private static let jsonObject = ["input": "1"]

    private let data = try! JSONSerialization.data(withJSONObject: DataFlowProcedureTests.jsonObject)

    private var dataLoadingProcedureSuccess: TransformProcedure<Void, Data>!
    private var dataLoadingProcedureFailure: TransformProcedure<Void, Data>!
    private var deserializationProcedureSuccess: TransformProcedure<Data, Any>!
    private var deserializationProcedureFailure: TransformProcedure<Data, Any>!
    private var interceptionProcedureSuccess: TransformProcedure<Any, Any>!
    private var interceptionProcedureFailure: TransformProcedure<Any, Any>!
    private var mappingProcedureSuccess: TransformProcedure<Any, Int>!
    private var mappingProcedureFailure: TransformProcedure<Any, Int>!

    override func setUp() {
        dataLoadingProcedureSuccess = TransformProcedure {
            return self.data
        }
        dataLoadingProcedureSuccess.input = pendingVoid
        dataLoadingProcedureFailure = TransformProcedure {
            throw Error.dataLoading
        }
        dataLoadingProcedureFailure.input = pendingVoid
        deserializationProcedureSuccess = TransformProcedure {
            return try! JSONSerialization.jsonObject(with: $0)
        }
        deserializationProcedureFailure = TransformProcedure {_ in
            throw Error.deserialization
        }
        interceptionProcedureSuccess = TransformProcedure {
            var dict = $0 as! [String: String]
            dict["input1"] = "2"
            return dict
        }
        interceptionProcedureFailure = TransformProcedure {_ in
            throw Error.intercepting
        }
        mappingProcedureSuccess = TransformProcedure {
            let dict = $0 as! [String: String]
            return dict.values.reduce(0) {
                return $0 + (Int($1) ?? 0)
            }
        }
        mappingProcedureFailure = TransformProcedure {_ in
            throw Error.mapping
        }
    }

    private func result(for procedure: DataFlowProcedure<Int>) -> Pending<ProcedureResult<Int>> {
        let expectation = self.expectation(description: "Output is available before completion")
        var result: Pending<ProcedureResult<Int>> = .pending
        procedure.addWillFinishBlockObserver { procedure, _, _ in
            result = procedure.output
        }
        procedure.addDidFinishBlockObserver { procedure, _ in
            XCTAssertEqual(procedure.output.success, result.success)
            XCTAssertEqual(procedure.output.error as NSError?, result.error as NSError?)
            expectation.fulfill()
        }
        ProcedureQueue().addOperation(procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        return result
    }

    func testAllProceduresSuccess() {
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          interceptionProcedure: interceptionProcedureSuccess,
                                          resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(3, self.result(for: procedure).success)
    }

    func testWithoutinterceptionProcedure() {
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(1, self.result(for: procedure).success)
    }

    func testFailureInDataLoadingProcedure() {
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureFailure,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          interceptionProcedure: interceptionProcedureSuccess,
                                          resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.dataLoading, self.result(for: procedure).error as? Error)
    }

    func testFailureInDeserializationProcedure() {
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureFailure,
                                          interceptionProcedure: interceptionProcedureSuccess,
                                          resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.deserialization, self.result(for: procedure).error as? Error)
    }

    func testFailureIninterceptionProcedure() {
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          interceptionProcedure: interceptionProcedureFailure,
                                          resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.intercepting, self.result(for: procedure).error as? Error)
    }

    func testFailureInMappingProcedure() {
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          interceptionProcedure: interceptionProcedureSuccess,
                                          resultMappingProcedure: mappingProcedureFailure)
        XCTAssertEqual(Error.mapping, self.result(for: procedure).error as? Error)
    }

    func testProcedureKitError() {
        let intercepting = TransformProcedure<Any, Any> {_ in
            throw ProcedureKitError.dependency(finishedWithError: Error.intercepting)
        }
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          interceptionProcedure: intercepting,
                                          resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.intercepting, self.result(for: procedure).error as? Error)
    }

    func testDependencyCancellationPreservesUnderlyingNetworkError() {
        let intercepting = TransformProcedure<Any, Any> {_ in
            throw ProcedureKitError.dependency(cancelledWithError:
                ProcedureKitError.dependency(finishedWithError: URLError(.notConnectedToInternet)))
        }
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          interceptionProcedure: intercepting,
                                          resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual((self.result(for: procedure).error as? URLError)?.code, .notConnectedToInternet)
    }

    func testSubclassWithoutSuperStillPublishesErrorAtDidFinish() {
        let procedure = NonForwardingDataFlowProcedure(
            dataLoadingProcedure: dataLoadingProcedureFailure,
            deserializationProcedure: deserializationProcedureSuccess,
            interceptionProcedure: interceptionProcedureSuccess,
            resultMappingProcedure: mappingProcedureSuccess)
        let finished = expectation(description: "Legacy final error handling")
        procedure.addWillFinishBlockObserver { procedure, _, _ in
            XCTAssertTrue(procedure.output.isPending)
        }
        procedure.addDidFinishBlockObserver { procedure, _ in
            XCTAssertEqual(procedure.output.error as? Error, .dataLoading)
            finished.fulfill()
        }
        ProcedureQueue().addOperation(procedure)
        wait(for: [finished], timeout: 2)
    }

    func testDidFinishPreservesSubclassResult() {
        let procedure = RecoveringDataFlowProcedure(
            dataLoadingProcedure: dataLoadingProcedureFailure,
            deserializationProcedure: deserializationProcedureSuccess,
            interceptionProcedure: interceptionProcedureSuccess,
            resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(result(for: procedure).success, 42)
    }

    func testSuccessfulResultIsAvailableToDependentProcedure() {
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          interceptionProcedure: interceptionProcedureSuccess,
                                          resultMappingProcedure: mappingProcedureSuccess)
        let dependent = TransformProcedure<Int, Int> { $0 + 1 }
        dependent.injectResult(from: procedure)
        let finished = expectation(description: "Dependent consumes the published result")
        dependent.addDidFinishBlockObserver { dependent, _ in
            XCTAssertEqual(dependent.output.success, 4)
            finished.fulfill()
        }
        let queue = ProcedureQueue()
        queue.addOperation(procedure)
        queue.addOperation(dependent)
        wait(for: [finished], timeout: 2)
    }

    func testCancellationBeforeExecutionPreservesOutput() {
        checkCancellation(afterStarting: false, error: nil)
        checkCancellation(afterStarting: false, error: .dataLoading)
    }

    func testCancellationDuringLoadingPreservesOutput() {
        checkCancellation(afterStarting: true, error: nil)
        checkCancellation(afterStarting: true, error: .dataLoading)
    }

    private func checkCancellation(afterStarting: Bool, error: Error?) {
        let started = afterStarting ? expectation(description: "Loading started") : nil
        var completeLoading: AsyncTransformProcedure<Void, Data>.FinishingBlock?
        let loading = AsyncTransformProcedure<Void, Data> { _, completion in
            completeLoading = completion
            started?.fulfill()
        }
        loading.input = pendingVoid
        let procedure = DataFlowProcedure(dataLoadingProcedure: loading,
            deserializationProcedure: TransformProcedure<Data, Any> { $0 },
            resultMappingProcedure: TransformProcedure<Any, Int> { _ in
                XCTFail("Cancelled flow must not map a result")
                return 0
            })
        let finished = expectation(description: "Cancelled flow finished")
        procedure.addWillFinishBlockObserver { procedure, _, _ in
            XCTAssertNil(procedure.output.success)
            XCTAssertEqual(procedure.output.error as? Error, error)
            XCTAssertEqual(procedure.output.isPending, error == nil)
        }
        procedure.addDidFinishBlockObserver { procedure, _ in
            XCTAssertTrue(procedure.isCancelled)
            XCTAssertNil(procedure.output.success)
            XCTAssertEqual(procedure.output.error as? Error, error)
            XCTAssertEqual(procedure.output.isPending, error == nil)
            finished.fulfill()
        }
        let queue = ProcedureQueue()
        if let started = started {
            queue.addOperation(procedure)
            wait(for: [started], timeout: 2)
            procedure.cancel(with: error)
            completeLoading?(.success(Data()))
        } else {
            procedure.cancel(with: error)
            queue.addOperation(procedure)
        }
        wait(for: [finished], timeout: 2)
    }
}

private final class NonForwardingDataFlowProcedure: DataFlowProcedure<Int> {
    override func procedureWillFinish(with error: Swift.Error?) {}
}

private final class RecoveringDataFlowProcedure: DataFlowProcedure<Int> {
    override func procedureWillFinish(with error: Swift.Error?) {
        super.procedureWillFinish(with: error)
        output = .ready(.success(42))
    }
}
