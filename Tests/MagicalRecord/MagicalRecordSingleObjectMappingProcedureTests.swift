//
//  MagicalRecordSingleObjectMappingProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import CoreData
#if canImport(ProcedureKit)
import ProcedureKit
#endif
#if ALL
@testable import All
#else
import EndpointProcedure
@testable import MagicalRecordMappingProcedureFactory
#endif

class MagicalRecordSingleObjectMappingProcedureTests: MagicalRecordMappingProcedureTests {

    override func testWithoutContext() {
        let input: Pending<Any> = .ready(["stringValue": "1"])
        let result: Pending<ProcedureResult<TestObject>> = self.procedureResult(for: input)
        XCTAssertEqual(TestObject.mr_countOfEntities(), 1)
        XCTAssertEqual("1", result.success?.mr_inThreadContext()?.stringValue)
    }

    override func testWithContext() {
        let context = NSManagedObjectContext.mr_context(withParent: NSManagedObjectContext.mr_rootSaving())
        let input: Pending<Any> = .ready(["stringValue": "1"])
        let result: Pending<ProcedureResult<TestObject>> = self.procedureResult(for: input, context: context)
        XCTAssertEqual(TestObject.mr_countOfEntities(), 0)
        XCTAssertEqual(TestObject.mr_countOfEntities(with: context), 1)
        XCTAssertEqual("1", result.success?.stringValue)
        context.reset()
        XCTAssertEqual(TestObject.mr_countOfEntities(), 0)
        XCTAssertEqual(TestObject.mr_countOfEntities(with: context), 0)
    }

    func testNoInput() {
        let result: Pending<ProcedureResult<TestObject>> = self.procedureResult()
        let error = result.error
        XCTAssertNotNil(error)
        XCTAssert(error is ProcedureKitError)
        XCTAssertEqual(error as? ProcedureKitError, ProcedureKitError.requirementNotSatisfied())
    }

    func testInvalidInput() {
        let input: Pending<Any> = .ready([["stringValue": "1"], ["stringValue": "2"]])
        let result: Pending<ProcedureResult<TestObject>> = self.procedureResult(for: input)
        let error = result.error
        XCTAssertNotNil(error)
        XCTAssert(error is ProcedureKitError)
        XCTAssertEqual(error as? ProcedureKitError, ProcedureKitError.requirementNotSatisfied())
    }

    func testUnableToMap() {
        let input: Pending<Any> = .ready(["stringValue": "1"])
        let result: Pending<ProcedureResult<InvalidTestObject>> = self.procedureResult(for: input)
        XCTAssertEqual(result.error.map { "\($0)"}, "\(MagicalRecordMappingProcedureError.unableMapResponse)")
    }

    func testInvalidEntityName() {
        let input: Pending<Any> = .ready(["stringValue": "1"])
        let result: Pending<ProcedureResult<InvalidEntityNameObject>> = self.procedureResult(for: input)
        XCTAssertEqual(result.error.map { "\($0)"}, "\(MagicalRecordMappingProcedureError.unableMapResponse)")
    }

    func testUnsupportedType() {
        let input: Pending<Any> = .ready(["stringValue": "1"])
        let result: Pending<ProcedureResult<NSManagedObject>> = self.procedureResult(for: input)
        XCTAssertEqual(result.error.map { "\($0)"}, "\(MagicalRecordMappingProcedureError.unsupportedType)")
    }

    override func testPerformMappingWithUnsuportedType() {
        let procedure = MagicalRecordSingleObjectMappingProcedure<[TestObject]>()
        procedure.input = .ready([:])
        let expectation = self.expectation(description: "Error expectation")
        do {
            try procedure.performMapping {_ in}
        } catch  MagicalRecordMappingProcedureError.unsupportedType {
            expectation.fulfill()
        } catch {}
        self.waitForExpectations(timeout: 0, handler: nil)
    }

    override func testManagedObjectType() {
        XCTAssert(MagicalRecordSingleObjectMappingProcedure<TestObject>.managedObjectType is TestObject.Type)
        XCTAssertNil(MagicalRecordSingleObjectMappingProcedure<NSManagedObject>.managedObjectType)
        XCTAssertNil(MagicalRecordSingleObjectMappingProcedure<[TestObject]>.managedObjectType)
        XCTAssertNil(MagicalRecordSingleObjectMappingProcedure<Set<TestObject>>.managedObjectType)
        XCTAssertNil(MagicalRecordSingleObjectMappingProcedure<String>.managedObjectType)
    }

    func testIsValid() {
        XCTAssert(MagicalRecordSingleObjectMappingProcedure<TestObject>.isValid)
        XCTAssertFalse(MagicalRecordSingleObjectMappingProcedure<NSManagedObject>.isValid)
        XCTAssertFalse(MagicalRecordSingleObjectMappingProcedure<[TestObject]>.isValid)
        XCTAssertFalse(MagicalRecordSingleObjectMappingProcedure<Set<TestObject>>.isValid)
        XCTAssertFalse(MagicalRecordSingleObjectMappingProcedure<String>.isValid)
    }
}

extension MagicalRecordSingleObjectMappingProcedureTests {
    fileprivate func procedureResult<Result>(for input: Pending<Any> = .pending,
                                     context: NSManagedObjectContext? = nil) -> Pending<ProcedureResult<Result>> {
        let procedure = MagicalRecordSingleObjectMappingProcedure<Result>()
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
