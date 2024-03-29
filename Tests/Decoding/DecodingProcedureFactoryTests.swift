//
//  EncoderProcedureFactoryTests.swift
//  EncoderProcedureFactoryTests
//
//  Created by Sviatoslav Yakymiv on 8/24/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import ProcedureKit
import EndpointProcedure
@testable import DecodingProcedureFactory

class EncoderProcedureFactoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSuccess() {
        let expectation = self.expectation(description: "")
        let factory = DecodingProcedureFactory(decoder: MockDecoder {_,_,_ in expectation.fulfill()})
        do {
            let procedure = try factory.responseMappingProcedure(for: TestDecodable.self)
            procedure.input = .ready(Data())
            ProcedureQueue.main.addOperation(procedure)
        } catch {
            XCTFail()
        }
        self.wait(for: [expectation], timeout: 1)
    }
    
    func testFailure() {
        let factory = DecodingProcedureFactory(decoder: MockDecoder {_,_,_ in })
        XCTAssertThrowsError(try factory.responseMappingProcedure(for: NSObject.self))
    }
}
