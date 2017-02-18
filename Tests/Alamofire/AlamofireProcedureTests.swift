//
//  AlamofireProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/18/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import ProcedureKit
import Alamofire
import EndpointProcedure
@testable import AlamofireProcedureFactory

class AlamofireProcedureTests: XCTestCase {

    private func isNoInteretConnection(error: Error?) -> Bool {
        return (error as? NSError)?.code == -1009
    }

    func testInit() {
        let url = "https://httpbin.org/get"
        let procedure = AlamofireProcedure(request: Alamofire.request(url))
        let expectation = self.expectation(description: "Request")
        let queue = ProcedureQueue.main
        procedure.addCompletionBlock {
            expectation.fulfill()
        }
        queue.add(operation: procedure)
        self.waitForExpectations(timeout: 60, handler: nil)

        guard !isNoInteretConnection(error: procedure.output.error) else {
            return
        }

        XCTAssertNil(procedure.output.error)
        XCTAssertNotNil(procedure.output.success?.data)
        XCTAssertNotNil(procedure.output.success?.urlResponse)

        let json = try! JSONSerialization.jsonObject(with: procedure.output.success!.data, options: [])
        XCTAssertEqual((json as! [String: Any])["url"] as! String, url)
    }

    func testFailure() {
        let expectation = self.expectation(description: "")
        let procedure = AlamofireProcedure(request: Alamofire.request(""))
        procedure.addDidFinishBlockObserver {_ in
            expectation.fulfill()
        }
        procedure.enqueue()
        self.waitForExpectations(timeout: 60, handler: nil)
        XCTAssertNotNil(procedure.output.error)
    }

    func testInvalidaDataRequest() {
        let url = "https://httpbin.org/get"
        let procedure = AlamofireProcedure(request: Alamofire.request(url).stream {_ in})
        let expectation = self.expectation(description: "Request")
        let queue = ProcedureQueue.main
        procedure.addCompletionBlock {
            expectation.fulfill()
        }
        queue.add(operation: procedure)
        self.waitForExpectations(timeout: 60, handler: nil)

        guard !isNoInteretConnection(error: procedure.output.error) else {
            return
        }

        XCTAssertEqual(procedure.output.error.map {"\($0)"}, "\(AlamofireProcedureError.invalidDataRequest)")
    }
}
