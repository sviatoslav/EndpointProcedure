//
//  EndpointProcedureFactoryTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 9/30/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import ProcedureKit
#if ALL
@testable import All
#else
@testable import EndpointProcedure
#endif

class EndpointProcedureFactoryTests: XCTestCase {

    let error = NSError(domain: "EndpointProcedureFactoryTests", code: 41241, userInfo: nil)

    func testSuccessfulCreation() {
        let factory = MockEndpointProcedureFactory(procedureCreation: {_ in return EndpointProcedure(error: self.error) })
        let procedure = factory.create(with: factory.defaultConfiguration)
        let expectation = self.expectation(description: "Execution")
        procedure.addDidFinishBlockObserver {_, _ in expectation.fulfill() }
        ProcedureQueue.main.add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(procedure.output.error as NSError? == self.error)
    }

    func testFailedCreation() {
        let factory = MockEndpointProcedureFactory(callback: {_,_ in})
        let procedure = factory.create(with: factory.defaultConfiguration)
        let expectation = self.expectation(description: "Execution")
        procedure.addDidFinishBlockObserver {_, _ in expectation.fulfill() }
        ProcedureQueue.main.add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(procedure.output.error as NSError? != self.error)
    }
}
