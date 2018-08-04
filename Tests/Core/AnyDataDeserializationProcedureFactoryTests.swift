//
//  AnyDataDeserializationProcedureFactoryTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 1/4/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
#if ALL
@testable import All
#else
@testable import EndpointProcedure
#endif

class AnyDataDeserializationProcedureFactoryTests: XCTestCase {
    private let json = ["key": "value"]
    private lazy var data: Data = {(try? JSONSerialization.data(withJSONObject: self.json, options: []))!}()

    func testSyncTransformationSuccess() {
        let factory = AnyDataDeserializationProcedureFactory {
            try JSONSerialization.jsonObject(with: $0, options: [])
        }
        self.checkReult(for: factory)
    }

    func testAsyncTransformationSuccess() {
        let factory = AnyDataDeserializationProcedureFactory { (data, completion) in
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

    func checkReult(for factory: DataDeserializationProcedureFactory) {
        let procedure = factory.dataDeserializationProcedure()
        procedure.input = .ready(self.data)
        let expectation = self.expectation(description: "")
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        procedure.enqueue()
        self.waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(self.json, (procedure.output.success.flatMap { $0 as? [String: String]} ?? [:]))
    }
}
