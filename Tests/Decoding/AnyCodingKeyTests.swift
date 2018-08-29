//
//  AnyCodingKeyTests.swift
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
}
