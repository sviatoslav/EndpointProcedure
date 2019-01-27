//
//  HTTPDataFlowProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
#if canImport(ProcedureKit)
import ProcedureKit
#endif
#if ALL
@testable import All
#else
@testable import EndpointProcedure
#endif

class HTTPDataFlowProcedureTests: XCTestCase {

    private enum Error: Int, Swift.Error {
        case dataLoading
        case validation
        case deserialization
        case interception
        case mapping
    }

    private static let jsonObject = ["input": "1"]

    private static let data = try! JSONSerialization.data(withJSONObject: HTTPDataFlowProcedureTests.jsonObject)

    private static let urlResponse = HTTPURLResponse(url: URL(fileURLWithPath: ""), statusCode: 200,
                                                     httpVersion: nil, headerFields: nil)!

    private let responseData = HTTPResponseData(urlResponse: HTTPDataFlowProcedureTests.urlResponse,
                                                data: HTTPDataFlowProcedureTests.data)

    private var dataLoadingProcedureSuccess: TransformProcedure<Void, HTTPResponseData>!
    private var dataLoadingProcedureFailure: TransformProcedure<Void, HTTPResponseData>!
    private var dataLoadingNilURLResponseProcedure: TransformProcedure<Void, HTTPResponseData>!
    private var validationProcedureSuccess: TransformProcedure<HTTPResponseData, Void>!
    private var validationProcedureFailure: TransformProcedure<HTTPResponseData, Void>!
    private var deserializationProcedureSuccess: TransformProcedure<Data, Any>!
    private var deserializationProcedureFailure: TransformProcedure<Data, Any>!
    private var interceptionProcedureSuccess: TransformProcedure<Any, Any>!
    private var interceptionProcedureFailure: TransformProcedure<Any, Any>!
    private var mappingProcedureSuccess: TransformProcedure<Any, Int>!
    private var mappingProcedureFailure: TransformProcedure<Any, Int>!

    override func setUp() {
        dataLoadingProcedureSuccess = TransformProcedure {
            return self.responseData
        }
        dataLoadingProcedureSuccess.input = pendingVoid
        dataLoadingProcedureFailure = TransformProcedure {
            throw Error.dataLoading
        }
        dataLoadingNilURLResponseProcedure = TransformProcedure {
            return HTTPResponseData(urlResponse: nil, data: self.responseData.data)
        }
        dataLoadingNilURLResponseProcedure.input = pendingVoid
        dataLoadingProcedureFailure.input = pendingVoid
        validationProcedureSuccess = TransformProcedure {_ in}
        validationProcedureFailure = TransformProcedure {_ in throw Error.validation}
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
            throw Error.interception
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
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              validationProcedure: validationProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              interceptionProcedure: interceptionProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(3, self.result(for: procedure).success)
    }

    func testWithoutValidationProcedure() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              interceptionProcedure: interceptionProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(3, self.result(for: procedure).success)
    }

    func testWithoutInterceptionProcedure() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              validationProcedure: validationProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(1, self.result(for: procedure).success)
    }


    func testWithoutValidationAndinterceptionProcedures() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureSuccess)
        let expectation = self.expectation(description: "")
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        ProcedureQueue().add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(1, procedure.output.success)
        XCTAssertFalse(procedure.urlResponse.isPending)
    }

    func testFailureInDataLoadingProcedure() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureFailure,
                                              validationProcedure: validationProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              interceptionProcedure: interceptionProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.dataLoading, self.result(for: procedure).error as? Error)
    }

    func testNilURLResponseInDataLoadingProcedure() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingNilURLResponseProcedure,
                                              validationProcedure: validationProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureSuccess)
        let expectation = self.expectation(description: "")
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        ProcedureQueue().add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(1, procedure.output.success)
        XCTAssert(procedure.urlResponse.isPending)
    }

    func testFailureInValidationProcedure() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              validationProcedure: validationProcedureFailure,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              interceptionProcedure: interceptionProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.validation, self.result(for: procedure).error as? Error)
    }

    func testFailureInDeserializationProcedure() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              validationProcedure: validationProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureFailure,
                                              interceptionProcedure: interceptionProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.deserialization, self.result(for: procedure).error as? Error)
    }

    func testFailureIninterceptionProcedure() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              validationProcedure: validationProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              interceptionProcedure: interceptionProcedureFailure,
                                              resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.interception, self.result(for: procedure).error as? Error)
    }

    func testFailureInMappingProcedure() {
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              validationProcedure: validationProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              interceptionProcedure: interceptionProcedureSuccess,
                                              resultMappingProcedure: mappingProcedureFailure)
        XCTAssertEqual(Error.mapping, self.result(for: procedure).error as? Error)
    }

    func testProcedureKitError() {
        let interception = TransformProcedure<Any, Any> {_ in
            throw ProcedureKitError.dependency(finishedWithErrors: [Error.interception])
        }
        let procedure = HTTPDataFlowProcedure(dataLoadingProcedure: dataLoadingProcedureSuccess,
                                              validationProcedure: validationProcedureSuccess,
                                              deserializationProcedure: deserializationProcedureSuccess,
                                              interceptionProcedure: interception,
                                              resultMappingProcedure: mappingProcedureSuccess)
        XCTAssertEqual(Error.interception, self.result(for: procedure).error as? Error)
    }}
