//
//  DefaultConfigurationProviderTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 9/30/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest

class DefaultConfigurationProviderTests: XCTestCase {
    func testCreateProcedure() {
        let mockFactory = MockEndpointProcedureFactory {
            XCTAssert($0 === ($1.dataLoadingProcedureFactory as? MockEndpointProcedureFactory))
            XCTAssert($0 === ($1.dataDeserializationProcedureFactory as? MockEndpointProcedureFactory))
            XCTAssert($0 === ($1.responseMappingProcedureFactory as? MockEndpointProcedureFactory))
        }
        _ = mockFactory.create()
    }
}
