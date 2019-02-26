//
//  AlamofireProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/18/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif
#if canImport(Alamofire)
import Alamofire
#endif
import EndpointProcedure
@testable import AlamofireProcedureFactory

class AlamofireProcedureTests: XCTestCase {

    private func isNoInteretConnection(error: Error?) -> Bool {
        return (error as NSError?)?.code == -1009
    }

    func testInit() {
        let url = "https://httpbin.org/get"
        let procedure = AlamofireProcedure(request: Alamofire.request(url))
        XCTAssertEqual(procedure.request.request?.url?.absoluteString, url)
    }

    func testCreationFailure() {
        let procedure = AlamofireProcedure(request: Alamofire.request(""))
        XCTAssertNil(procedure.request.request)
    }

    func testValidDataRequest() {
//        let url = Bundle(for: type(of: self)).url(forResource: "mock", withExtension: "json")!.absoluteString
        let url = URL(string: "data:;base64,\("{}".data(using: .utf8)!.base64EncodedString())")!
        let procedure = AlamofireProcedure(request: Alamofire.request(url))
        let expectation = self.expectation(description: "Request")
        let queue = ProcedureQueue.main
        procedure.addCompletionBlock {
            expectation.fulfill()
        }
        queue.add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)

        XCTAssertNil(procedure.output.error)
    }

    func testLoadingFailureRequest() {
        let procedure = AlamofireProcedure(request: Alamofire.request("file://directory"))
        let expectation = self.expectation(description: "Request")
        let queue = ProcedureQueue.main
        procedure.addCompletionBlock {
            expectation.fulfill()
        }
        queue.add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)

        XCTAssertNotNil(procedure.output.error)
    }

    func testInvalidaDataRequest() {
        let url = URL(string: "data:;base64,\("{}".data(using: .utf8)!.base64EncodedString())")!
        let procedure = AlamofireProcedure(request: Alamofire.request(url).stream {_ in})
        let expectation = self.expectation(description: "Request")
        let queue = ProcedureQueue.main
        procedure.addCompletionBlock {
            expectation.fulfill()
        }
        queue.add(operation: procedure)
        self.waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(procedure.output.error.map {"\($0)"}, "\(AlamofireProcedureError.invalidDataRequest)")
    }
}
