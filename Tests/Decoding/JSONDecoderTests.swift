//
//  JSONDecoderTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/29/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
@testable import DecodingProcedureFactory

class JSONDecoderTests: XCTestCase {
    
    func testNestedObject() {
        do {
            let encoder = JSONDecoder()
            let object = try encoder.decode(TestDecodable.self, from: TestData.data(for: TestData.validNestedObject,
                                                                                 using: TestData.jsonSerialization),
                                            codingPath: TestData.nestedKeys)
            XCTAssertEqual(object.b, "a")
        } catch {
            XCTFail()
        }
    }
    
    func testNotNestedObject() {
        do {
            let encoder = JSONDecoder()
            let object = try encoder.decode(TestDecodable.self, from: TestData.data(for: TestData.notNestedObject,
                                                                                 using: TestData.jsonSerialization),
                                            codingPath: [])
            XCTAssertEqual(object.b, "a")
        } catch {
            XCTFail()
        }
    }
    
    func testInvalidNestedObject() {
        do {
            let encoder = JSONDecoder()
            _ = try encoder.decode(TestDecodable.self, from: TestData.data(for: TestData.invalidNestedObject,
                                                                                 using: TestData.jsonSerialization),
                                            codingPath: TestData.nestedKeys)
            XCTFail()
        } catch let error {
            guard case DecodingError.keyNotFound(_, _)? = error as? DecodingError else {
                XCTFail()
                return
            }
        }
    }
    
    func testNotValidJSON() {
        do {
            let encoder = JSONDecoder()
            _ = try encoder.decode(TestDecodable.self,
                                   from: TestData.data(for: TestData.invalidNestedObject,
                                                       using: TestData.plistSerialization(withFormat: .binary)),
                                   codingPath: TestData.nestedKeys)
            XCTFail()
        } catch let error {
            guard case DecodingError.dataCorrupted(_)? = error as? DecodingError else {
                XCTFail()
                return
            }
        }
    }
}
