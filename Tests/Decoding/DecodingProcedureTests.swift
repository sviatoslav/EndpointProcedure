//
//  DecodingProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/29/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import ProcedureKit
#if ALL
@testable import All
#else
@testable import DecodingProcedureFactory
#endif

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
}

