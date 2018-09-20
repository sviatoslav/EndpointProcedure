//
//  PropertyListEncoderTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/29/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
#if ALL
@testable import All
#else
@testable import DecodingProcedureFactory
#endif

class PropertyListEncoderTests: XCTestCase {
    
    func testNestedObject() {
        do {
            let encoder = PropertyListDecoder()
            let object = try encoder.decode(TestDecodable.self,
                                            from: TestData.data(for: TestData.validNestedObject,
                                                                using: TestData.plistSerialization(withFormat: .xml)),
                                            codingPath: TestData.nestedKeys)
            XCTAssertEqual(object.b, "a")
        } catch {
            XCTFail()
        }
    }
    
    func testNotNestedObject() {
        do {
            let encoder = PropertyListDecoder()
            let object = try encoder.decode(TestDecodable.self,
                                            from: TestData.data(for: TestData.notNestedObject,
                                                                using: TestData.plistSerialization(withFormat: .xml)),
                                            codingPath: [])
            XCTAssertEqual(object.b, "a")
        } catch {
            XCTFail()
        }
    }
    
    func testInvalidNestedObject() {
        do {
            let encoder = PropertyListDecoder()
            _ = try encoder.decode(TestDecodable.self,
                                   from: TestData.data(for: TestData.invalidNestedObject,
                                                       using: TestData.plistSerialization(withFormat: .xml)),
                                   codingPath: TestData.nestedKeys)
            XCTFail()
        } catch let error {
            guard case DecodingError.keyNotFound(_, _)? = error as? DecodingError else {
                XCTFail()
                return
            }
        }
    }
    
    func testNotValidPlist() {
        do {
            let encoder = PropertyListDecoder()
            _ = try encoder.decode(TestDecodable.self,
                                   from: TestData.data(for: TestData.invalidNestedObject,
                                                       using: TestData.jsonSerialization),
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
