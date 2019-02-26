//
//  DecodingProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/29/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
#if canImport(ProcedureKit)
import ProcedureKit
#endif
@testable import DecodingProcedureFactory

class DecodingProcedureTests: XCTestCase {
    func testNestedDataInput() {
        let expectation = self.expectation(description: "Correct nested data")
        let inputData = Data()
        let decoder = MockDecoder {type, data, codingPath in
            XCTAssert(type == TestDecodable.self)
            XCTAssert(data == inputData)
            XCTAssert(codingPath.map({ $0.stringValue }) == TestData.nestedKeys.map({ $0.stringValue }))
            expectation.fulfill()
        }
        let procedure = DecodingProcedure<TestDecodable>(decoder: decoder)
        procedure.input = .ready(NestedData(codingPath: TestData.nestedKeys, data: inputData))
        ProcedureQueue.main.add(operation: procedure)
        self.wait(for: [expectation], timeout: 1)
    }
    
    func testDataInput() {
        let expectation = self.expectation(description: "Correct data")
        let inputData = Data()
        let decoder = MockDecoder {type, data, codingPath in
            XCTAssert(type == TestDecodable.self)
            XCTAssert(data == inputData)
            XCTAssert(codingPath.isEmpty)
            expectation.fulfill()
        }
        let procedure = DecodingProcedure<TestDecodable>(decoder: decoder)
        procedure.input = .ready(inputData)
        ProcedureQueue.main.add(operation: procedure)
        self.wait(for: [expectation], timeout: 1)
    }
    
    func testInvalidInput() {
        let expectation = self.expectation(description: "Error")
        let decoder = MockDecoder {_,_,_ in XCTFail() }
        let procedure = DecodingProcedure<TestDecodable>(decoder: decoder)
        procedure.input = .ready(String())
        procedure.addDidFinishBlockObserver { (procedure, _) in
            XCTAssertEqual(ProcedureKitError.requirementNotSatisfied(), procedure.output.error as? ProcedureKitError)
            expectation.fulfill()
        }
        ProcedureQueue.main.add(operation: procedure)
        self.wait(for: [expectation], timeout: 1)
    }
    
    func testUnsupportedOutputType() {
        let expectation = self.expectation(description: "Error")
        let decoder = MockDecoder {_,_,_ in XCTFail() }
        let procedure = DecodingProcedure<NSObject>(decoder: decoder)
        procedure.input = .ready(Data())
        procedure.addDidFinishBlockObserver { (procedure, _) in
            guard case DecodingProcedureError.outputDoesNotConformToDecodable?
                = procedure.output.error as? DecodingProcedureError else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        ProcedureQueue.main.add(operation: procedure)
        self.wait(for: [expectation], timeout: 1)
    }

    func testJSONObjectDecoding() {
        let expectation = self.expectation(description: "Execution")
        let data = TestData.data(for: TestData.notNestedObject, using: TestData.jsonSerialization)
        let procedure = DecodingProcedure<TestDecodable>(decoder: JSONDecoder())
        procedure.input = .ready(data)
        procedure.addDidFinishBlockObserver { (procedure, _) in
            expectation.fulfill()
        }
        ProcedureQueue.main.add(operation: procedure)
        self.wait(for: [expectation], timeout: 1)
        XCTAssertEqual(procedure.output.success?.b, "a")
    }

    func testJSONArrayDecoding() {
        let expectation = self.expectation(description: "Execution")
        let data = TestData.data(for: TestData.notNestedArray, using: TestData.jsonSerialization)
        let procedure = DecodingProcedure<[TestDecodable]>(decoder: JSONDecoder())
        procedure.input = .ready(data)
        procedure.addDidFinishBlockObserver { (procedure, _) in
            expectation.fulfill()
        }
        ProcedureQueue.main.add(operation: procedure)
        self.wait(for: [expectation], timeout: 1)
        XCTAssertEqual(procedure.output.success?.count, 2)
        XCTAssertEqual(procedure.output.success?.first?.b, "a")
        XCTAssertEqual(procedure.output.success?.last?.b, "a")
    }

    func testInvalidFormatJSONObjectDecoding() {
        let expectation = self.expectation(description: "Execution")
        let data = TestData.data(for: TestData.validNestedObject, using: TestData.jsonSerialization)
        let procedure = DecodingProcedure<TestDecodable>(decoder: JSONDecoder())
        procedure.input = .ready(data)
        procedure.addDidFinishBlockObserver { (procedure, _) in
            expectation.fulfill()
        }
        ProcedureQueue.main.add(operation: procedure)
        self.wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(procedure.output.error)
    }

    func testIncorrectDecodableType() {
        let expectation = self.expectation(description: "Execution")
        let data = TestData.data(for: TestData.notNestedObject, using: TestData.jsonSerialization)
        let procedure = InvalidDecodingProcedure<NSObject>(decoder: JSONDecoder())
        procedure.input = .ready(data)
        procedure.addDidFinishBlockObserver { (procedure, _) in
            expectation.fulfill()
        }
        ProcedureQueue.main.add(operation: procedure)
        self.wait(for: [expectation], timeout: 1)
        XCTAssert((procedure.output.error as? DecodingProcedureError) == .outputDoesNotConformToDecodable)
    }
}

class InvalidDecodingProcedure<T>: DecodingProcedure<T> {
    override class var decodableType: Decodable.Type? {
        return TestDecodable.self
    }
}

