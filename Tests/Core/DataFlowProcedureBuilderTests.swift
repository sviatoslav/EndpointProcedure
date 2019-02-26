//
//  DataFlowProcedureBuilderTests.swift
//  EndpointProcedureTests
//
//  Created by Sviatoslav Yakymiv on 2/26/19.
//

import XCTest
import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif
@testable import EndpointProcedure

class DataFlowProcedureBuilderTests: XCTestCase {
    func testAllComponentsOfDataFlowProcedure() {
        let loading = TransformProcedure<Void, Data> { return "[1, 2, 3, 4]".data(using: .utf8)! }
        loading.input = pendingVoid
        let procedure = DataFlowProcedureBuilder.load(using: loading).deserialize(using: TransformProcedure<Data, Any> {
            return try JSONSerialization.jsonObject(with: $0, options: [])
        }).intercept(using: TransformProcedure<Any, Any> {
            if let array = $0 as? [Int] {
                return array.map({ $0 * $0 })
            }
            return $0
        }).map(using: TransformProcedure<Any, Int> { return ($0 as! [Int]).reduce(0, +) })
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.success, 30)
    }

    func testAllComponentsOfHTTPDataFlowProcedure() {
        enum Error: Swift.Error {
            case value
        }
        let schemaExpectation = self.expectation(description: "schema expectation")
        let response = HTTPURLResponse(url: URL(string: "myurl://")!, mimeType: nil, expectedContentLength: 0,
                                       textEncodingName: nil)
        let loading = TransformProcedure<Void, HTTPResponseData> {
            return HTTPResponseData(urlResponse: response,
                                    data: "[1, 2, 3, 4]".data(using: .utf8)!)
        }
        loading.input = pendingVoid
        let procedure = DataFlowProcedureBuilder.load(using: loading)
            .validate(using: TransformProcedure<HTTPResponseData, Void> {
                guard $0.urlResponse == response else { throw Error.value }
                schemaExpectation.fulfill()
            })
            .deserialize(using: TransformProcedure<Data, Any> {
                return try JSONSerialization.jsonObject(with: $0, options: [])

            }).intercept(using: TransformProcedure<Any, Any> {
                if let array = $0 as? [Int] {
                    return array.map({ $0 * $0 })
                }
                return $0
            }).map(using: TransformProcedure<Any, Int> { return ($0 as! [Int]).reduce(0, +) })
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.success, 30)
    }

    func testDefaultComponentsOfHTTPDataFlowProcedure() {
        let response = HTTPURLResponse(url: URL(string: "myurl://")!, mimeType: nil, expectedContentLength: 0,
                                       textEncodingName: nil)
        let loading = TransformProcedure<Void, HTTPResponseData> {
            return HTTPResponseData(urlResponse: response,
                                    data: "[1, 2, 3, 4]".data(using: .utf8)!)
        }
        loading.input = pendingVoid
        let procedure = DataFlowProcedureBuilder.load(using: loading)
            .map(using: TransformProcedure<Any, Int> {
                try JSONDecoder().decode([Int].self, from: $0 as! Data).reduce(0, +)
            })
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.success, 10)
    }
}

extension DataFlowProcedureBuilderTests {
    fileprivate func procedureResult<T>(for procedure: DataFlowProcedure<T>) -> Pending<ProcedureResult<T>> {
        let expectation = self.expectation(description: "")
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        ProcedureQueue().add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        return procedure.output
    }
}

