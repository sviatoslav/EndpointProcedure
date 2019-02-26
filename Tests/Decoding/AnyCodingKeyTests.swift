//
//  AnyCodingKeyTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/29/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
@testable import DecodingProcedureFactory

class AnyCodingKeyTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testString() {
        let key = AnyCodingKey(stringValue: "1")
        XCTAssertNotNil(key)
        XCTAssertEqual(key?.stringValue, "1")
        XCTAssertNil(key?.intValue)
    }
    
    func testInt() {
        let key = AnyCodingKey(intValue: 1)
        XCTAssertNotNil(key)
        XCTAssertEqual(key?.stringValue, "1")
        XCTAssertEqual(key?.intValue, 1)
    }

    func testStringLiteral() {
        let key: AnyCodingKey = "1"
        XCTAssertEqual(key.stringValue, "1")
        XCTAssertNil(key.intValue)
    }

    func testIntLiteral() {
        let key: AnyCodingKey = 1
        XCTAssertEqual(key.stringValue, "1")
        XCTAssertEqual(key.intValue, 1)
    }
}
