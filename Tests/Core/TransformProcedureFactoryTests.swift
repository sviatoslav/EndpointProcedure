//
//  TransformProcedureFactoryTests.swift
//  EndpointProcedureTests
//
//  Created by Sviatoslav Yakymiv on 5/11/19.
//

import XCTest
import ProcedureKit
@testable import EndpointProcedure


class TransformProcedureFactoryTests: XCTestCase {
    private let json = ["key": "value"]
    private lazy var data: Data = {(try? JSONSerialization.data(withJSONObject: self.json, options: []))!}()
    
    func testSyncTransformationSuccess() {
        let factory = AnyTransformProcedureFactory<Data, Any> {
            try JSONSerialization.jsonObject(with: $0, options: [])
        }
        self.checkReult(for: factory)
    }
    
    func testAsyncTransformationSuccess() {
        let factory = AnyTransformProcedureFactory<Data, Any> { (data, completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    completion(.success(json))
                } catch let error {
                    completion(.failure(error))
                }
            }
        }
        self.checkReult(for: factory)
    }
    
    func checkReult(for factory: AnyTransformProcedureFactory<Data, Any>) {
        let procedure = factory.anyProcedure()
        let inputProcedure = factory.anyInputProcedure()
        self.run(procedure: procedure)
        self.run(procedure: inputProcedure)
        XCTAssertEqual(self.json, (procedure.output.success.flatMap { $0 as? [String: String]} ?? [:]))
        XCTAssertNil(inputProcedure.error)
    }
    
    private func run<T: Procedure>(procedure: T) where T: InputProcedure, T.Input == Data {
        procedure.input = .ready(self.data)
        let expectation = self.expectation(description: "")
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        ProcedureQueue().addOperation(procedure)
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
}
