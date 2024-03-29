//
//  FileDataLoadingProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/18/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import ProcedureKit
@testable import EndpointProcedure

class ContentsOfURLLoadingProcedureTests: XCTestCase {

    private static let url = URL(string: "data:;base64,\("{key: value}".data(using: .utf8)!.base64EncodedString())")!
    private static let expectedData = try! Data(contentsOf: ContentsOfURLLoadingProcedureTests.url)

    func testLoadingFromFile() {
        self.loadData(from: ContentsOfURLLoadingProcedureTests.url)
    }

    func testLoadingFromDataURL() {
        let base64 = ContentsOfURLLoadingProcedureTests.expectedData.base64EncodedString()
        let url = URL(string: "data:;base64,\(base64)")!
        self.loadData(from: url)
    }

    private func loadData(from url: URL) {
        let procedure = ContentsOfURLLoadingProcedure(url: url)
        let expectation = self.expectation(description: "Waiting for operations")
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        ProcedureQueue().addOperation(procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(procedure.output.success, ContentsOfURLLoadingProcedureTests.expectedData)
    }

    func testFailure() {
        let url = Bundle(for: type(of: self)).bundleURL
        let procedure = ContentsOfURLLoadingProcedure(url: url)
        let expectation = self.expectation(description: "Waiting for operations")
        procedure.addDidFinishBlockObserver { (procedure, _) in
            XCTAssertNotNil(procedure.output.error)
            expectation.fulfill()
        }
        ProcedureQueue().addOperation(procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
}
