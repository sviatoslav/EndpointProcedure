//
//  MagicalRecordMappingProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
#if canImport(MagicalRecord)
import MagicalRecord
#endif
#if canImport(ProcedureKit)
import ProcedureKit
#endif
#if ALL
@testable import All
#else
import EndpointProcedure
@testable import MagicalRecordMappingProcedureFactory
#endif

class MagicalRecordMappingProcedureTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MagicalRecord.setLoggingLevel(.off)
        MagicalRecord.setDefaultModelFrom(type(of: self))
        MagicalRecord.setupCoreDataStackWithInMemoryStore()
    }

    override func tearDown() {
        super.tearDown()
        MagicalRecord.save(blockAndWait: {
            TestObject.mr_findAll(in: $0)?.forEach {
                $0.mr_deleteEntity()
            }
        })
    }

    func testWithoutContext() {
        let input: Pending<Any> = .ready(["stringValue": "1"])
        let result: Pending<ProcedureResult<TestObject>> = self.procedureResult(for: input)
        XCTAssertEqual(result.error.map {"\($0)"},
                       "\(MagicalRecordMappingProcedureError.unsupportedType)")
    }

    func testWithContext() {
        let context = NSManagedObjectContext.mr_context(withParent: NSManagedObjectContext.mr_rootSaving())
        let input: Pending<Any> = .ready(["stringValue": "1"])
        let result: Pending<ProcedureResult<TestObject>> = self.procedureResult(for: input, context: context)
        XCTAssertEqual(result.error.map {"\($0)"},
                       "\(MagicalRecordMappingProcedureError.unsupportedType)")
    }

    func testManagedObjectType() {
        XCTAssertNil(MagicalRecordMappingProcedure<TestObject>.managedObjectType)
        XCTAssertNil(MagicalRecordMappingProcedure<[TestObject]>.managedObjectType)
        XCTAssertNil(MagicalRecordMappingProcedure<NSManagedObject>.managedObjectType)
        XCTAssertNil(MagicalRecordMappingProcedure<[NSManagedObject]>.managedObjectType)
        XCTAssertNil(MagicalRecordMappingProcedure<InvalidTestObject>.managedObjectType)
        XCTAssertNil(MagicalRecordMappingProcedure<[InvalidTestObject]>.managedObjectType)
        XCTAssertNil(MagicalRecordMappingProcedure<Any>.managedObjectType)
        XCTAssertNil(MagicalRecordMappingProcedure<[Any]>.managedObjectType)
    }

    func testPerformMappingWithUnsuportedType() {
        class MagicalRecordMappingProcedureMock<T>: MagicalRecordMappingProcedure<T> {
            override class var managedObjectType: NSManagedObject.Type? {
                return T.self as? NSManagedObject.Type
            }
        }
        let procedure = MagicalRecordMappingProcedureMock<TestObject>()
        let expectation = self.expectation(description: "Procedure expectation")
        procedure.input = .ready([:])
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        procedure.enqueue()
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(procedure.output.error.map {"\($0)"},
                       "\(MagicalRecordMappingProcedureInternalError.unoverridenPerformMappingMethod)")
    }
}

extension MagicalRecordMappingProcedureTests {
    fileprivate func procedureResult<Result>(for input: Pending<Any> = .pending,
                                     context: NSManagedObjectContext? = nil) -> Pending<ProcedureResult<Result>> {
        let procedure = MagicalRecordMappingProcedure<Result>()
        if context != nil {
            procedure.managedObjectContext = context
        }
        let expectation = self.expectation(description: "Procedure expectation")
        procedure.input = input
        procedure.addDidFinishBlockObserver {_,_ in
            expectation.fulfill()
        }
        procedure.enqueue()
        self.waitForExpectations(timeout: 1, handler: nil)
        return procedure.output
    }
}
