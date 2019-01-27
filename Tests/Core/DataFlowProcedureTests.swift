//
//  DataFlowProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif
#if ALL
@testable import All
#else
@testable import EndpointProcedure
#endif

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
        let expectation = self.expectation(description: "")
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        ProcedureQueue().add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        return procedure.output
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
            throw ProcedureKitError.dependency(finishedWithErrors: [Error.intercepting])
        }
        let procedure = DataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                          deserializationProcedure: deserializationProcedureSuccess,
                                          interceptionProcedure: intercepting,
                                          resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.intercepting, self.result(for: procedure).error as? Error)
    }
}
