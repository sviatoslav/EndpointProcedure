//
//  MagicalRecordObjectsArrayMappingProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import CoreData
import ProcedureKit
#if ALL
@testable import All
#else
import EndpointProcedure
@testable import MagicalRecordMappingProcedureFactory
#endif

class MagicalRecordObjectsArrayMappingProcedureTests: MagicalRecordMappingProcedureTests {
    override func testWithoutContext() {
        let input: Pending<Any> = .ready([["stringValue": "1"], ["stringValue": "2"]])
        let result: Pending<ProcedureResult<[TestObject]>> = self.procedureResult(for: input)
        let strings = result.success?.compactMap { $0.mr_inThreadContext()?.stringValue }.sorted()
        XCTAssertEqual("1", strings?.first)
        XCTAssertEqual("2", strings?.last)
    }

    override func testWithContext() {
        let context = NSManagedObjectContext.mr_context(withParent: NSManagedObjectContext.mr_rootSaving())
        let input: Pending<Any> = .ready([["stringValue": "1"], ["stringValue": "2"]])
        let result: Pending<ProcedureResult<[TestObject]>> = self.procedureResult(for: input, context: context)
        XCTAssertEqual(TestObject.mr_countOfEntities(), 0)
        XCTAssertEqual(TestObject.mr_countOfEntities(with: context), 2)
        let strings = result.success?.compactMap { $0.stringValue }.sorted()
        XCTAssertEqual("1", strings?.first)
        XCTAssertEqual("2", strings?.last)
        context.reset()
        XCTAssertEqual(TestObject.mr_countOfEntities(), 0)
        XCTAssertEqual(TestObject.mr_countOfEntities(with: context), 0)
    }

    func testNoInput() {
        let result: Pending<ProcedureResult<[TestObject]>> = self.procedureResult()
        let error = result.error
        XCTAssertNotNil(error)
        XCTAssert(error is ProcedureKitError)
        XCTAssertEqual(error as? ProcedureKitError, ProcedureKitError.requirementNotSatisfied())
    }

    func testInvalidInput() {
        let input: Pending<Any> = .ready(["stringValue": "2"])
        let result: Pending<ProcedureResult<[TestObject]>> = self.procedureResult(for: input)
        let error = result.error
        XCTAssertNotNil(error)
        XCTAssert(error is ProcedureKitError)
        XCTAssertEqual(error as? ProcedureKitError, ProcedureKitError.requirementNotSatisfied())
    }

    func testUnableToMap() {
        let input: Pending<Any> = .ready([["stringValue": "1"], ["stringValue": "2"]])
        let result: Pending<ProcedureResult<[InvalidTestObject]>> = self.procedureResult(for: input)
        XCTAssertEqual(result.error.map { "\($0)"}, "\(MagicalRecordMappingProcedureError.unableMapResponse)")
    }

    func testInvalidEntityName() {
        let input: Pending<Any> = .ready([["stringValue": "1"], ["stringValue": "2"]])
        let result: Pending<ProcedureResult<[InvalidEntityNameObject]>> = self.procedureResult(for: input)
        XCTAssertEqual(result.error.map { "\($0)"}, "\(MagicalRecordMappingProcedureError.unableMapResponse)")
    }

    func testUnsupportedType() {
        let input: Pending<Any> = .ready([["stringValue": "1"]])
        let result: Pending<ProcedureResult<[NSManagedObject]>> = self.procedureResult(for: input)
        XCTAssertEqual(result.error.map { "\($0)"}, "\(MagicalRecordMappingProcedureError.unsupportedType)")
    }

    override func testManagedObjectType() {
        XCTAssert(MagicalRecordObjectsArrayMappingProcedure<[TestObject]>.managedObjectType is TestObject.Type)
        XCTAssertNil(MagicalRecordObjectsArrayMappingProcedure<[NSManagedObject]>.managedObjectType)
        XCTAssertNil(MagicalRecordObjectsArrayMappingProcedure<TestObject>.managedObjectType)
        XCTAssertNil(MagicalRecordObjectsArrayMappingProcedure<Set<TestObject>>.managedObjectType)
        XCTAssertNil(MagicalRecordObjectsArrayMappingProcedure<String>.managedObjectType)
    }

    func testIsValid() {
        XCTAssert(MagicalRecordObjectsArrayMappingProcedure<[TestObject]>.isValid)
        XCTAssertFalse(MagicalRecordObjectsArrayMappingProcedure<[NSManagedObject]>.isValid)
        XCTAssertFalse(MagicalRecordObjectsArrayMappingProcedure<TestObject>.isValid)
        XCTAssertFalse(MagicalRecordObjectsArrayMappingProcedure<Set<TestObject>>.isValid)
        XCTAssertFalse(MagicalRecordObjectsArrayMappingProcedure<String>.isValid)
    }

    override func testPerformMappingWithUnsuportedType() {
        let procedure = MagicalRecordObjectsArrayMappingProcedure<TestObject>()
        procedure.input = .ready([])
        let expectation = self.expectation(description: "Error expectation")
        do {
            try procedure.performMapping {_ in}
        } catch  MagicalRecordMappingProcedureError.unsupportedType {
            expectation.fulfill()
        } catch {}
        self.waitForExpectations(timeout: 0, handler: nil)
    }
}

extension MagicalRecordObjectsArrayMappingProcedureTests {
    fileprivate func procedureResult<Result>(for input: Pending<Any> = .pending,
                                     context: NSManagedObjectContext? = nil) -> Pending<ProcedureResult<Result>> {
        let procedure = MagicalRecordObjectsArrayMappingProcedure<Result>()
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
