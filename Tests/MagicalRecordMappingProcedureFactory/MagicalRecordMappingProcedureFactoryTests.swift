//
//  MagicalRecordMappingProcedureFactoryTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/22/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import MagicalRecord
import ProcedureKit
import EndpointProcedure
@testable import MagicalRecordMappingProcedureFactory

class MagicalRecordMappingProcedureFactoryTests: XCTestCase {

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

    func testSingleObjectMappingProcedureСreationWithoutContext() {
        do {
            let procedure = try MagicalRecordMappingProcedureFactory().responseMappingProcedure(for: TestObject.self)
            procedure.input = .ready(["stringValue": "1"])
            let output = self.output(for: procedure)
            XCTAssertNotNil(output.success)
        } catch {
            XCTFail()
        }
    }

    func testObjectsArrayMappingProcedureСreationWithoutContext() {
        do {
            let procedure = try MagicalRecordMappingProcedureFactory().responseMappingProcedure(for: [TestObject].self)
            procedure.input = .ready([["stringValue": "1"], ["stringValue": "2"]])
            let output = self.output(for: procedure)
            guard let array = output.success else {
                XCTFail()
                return
            }
            XCTAssertEqual(array.count, 2)
        } catch {
            XCTFail()
        }
    }

    func testSingleObjectMappingProcedureСreationWithContext() {
        do {
            let context = NSManagedObjectContext.mr_()
            let procedure = try MagicalRecordMappingProcedureFactory(managedObjectContext: context)
                                                                    .responseMappingProcedure(for: TestObject.self)
            procedure.input = .ready(["stringValue": "1"])
            let output = self.output(for: procedure)
            XCTAssertNotNil(output.success)
            XCTAssertEqual(output.success?.managedObjectContext, context)
        } catch {
            XCTFail()
        }
    }

    func testObjectsArrayMappingProcedureСreationWithContext() {
        do {
            let context = NSManagedObjectContext.mr_()
            let procedure = try MagicalRecordMappingProcedureFactory(managedObjectContext: context)
                                                                    .responseMappingProcedure(for: [TestObject].self)
            procedure.input = .ready([["stringValue": "1"], ["stringValue": "2"]])
            let output = self.output(for: procedure)
            guard let array = output.success else {
                XCTFail()
                return
            }
            XCTAssertEqual(array.count, 2)
            XCTAssertEqual(array.first?.managedObjectContext, context)
            XCTAssertEqual(array.last?.managedObjectContext, context)
        } catch {
            XCTFail()
        }
    }

    func testProcedureCreationForStringResponce() {
        do {
            _ = try MagicalRecordMappingProcedureFactory().responseMappingProcedure(for: String.self)
            XCTFail()
        } catch MagicalRecordMappingProcedureError.unsupportedType {
        } catch {
            XCTFail()
        }
    }

    func testProcedureCreationForStringArray() {
        do {
            _ = try MagicalRecordMappingProcedureFactory().responseMappingProcedure(for: [String].self)
            XCTFail()
        } catch MagicalRecordMappingProcedureError.unsupportedType {
        } catch {
            XCTFail()
        }
    }

    func testProcedureCreationForSetOfManagedObjectSubclass() {
        do {
            _ = try MagicalRecordMappingProcedureFactory().responseMappingProcedure(for: Set<TestObject>.self)
            XCTFail()
        } catch MagicalRecordMappingProcedureError.unsupportedType {
        } catch {
            XCTFail()
        }
    }

    private func output<T: OutputProcedure>(for procedure: T) -> Pending<ProcedureResult<T.Output>>
                                                                    where T: Procedure, T: InputProcedure {
        let expectation = self.expectation(description: "")
        procedure.addDidFinishBlockObserver {_ in
            expectation.fulfill()
        }
        procedure.enqueue()
        self.waitForExpectations (timeout: 5, handler: nil)
        return procedure.output
    }
}
