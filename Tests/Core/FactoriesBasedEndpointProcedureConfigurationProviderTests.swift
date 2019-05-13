//
//  FactoriesBasedEndpointProcedureConfigurationProviderTests.swift
//  EndpointProcedureTests
//
//  Created by Sviatoslav Yakymiv on 5/12/19.
//

import XCTest
import EndpointProcedure
import ProcedureKit

class FactoriesBasedEndpointProcedureConfigurationProviderTests: XCTestCase {
    enum Error: Swift.Error {
        case validation
        case deserialization
        case interception
    }
    
    private let defaultProviderConfiguration = FactoriesBasedEndpointProcedureConfigurationProvider(
        request: MockRequestProcedureFactory(), responseMapping: MockResponseMappingProcedureFactory()
        ).configuration(forRequestData: HTTPRequestData.Builder.for(URL(string: "f://")!).build(), responseType: Void.self)
    
    func testDefaultProviderRequestFactory() {
        do {
            _ = try defaultProviderConfiguration.requestProcedure()
        } catch let error {
            XCTAssertEqual(error as? MockRequestProcedureFactory.Error, MockRequestProcedureFactory.error)
        }
    }
    func testDefaultProviderValidationFactory() {
        let procedure = self.defaultProviderConfiguration.validationProcedure()
        self.run(procedure: procedure, withInput: HTTPResponseData(urlResponse: nil, data: Data()))
        XCTAssertNil(procedure.error)
    }
    func testDefaultProviderDeserializationFactory() {
        let input = UUID().uuidString
        let procedure = self.defaultProviderConfiguration.deserializationProcedure()
        self.run(procedure: procedure, withInput: input.data(using: .utf8)!)
        XCTAssertEqual(procedure.output.success.flatMap({ $0 as? Data }).flatMap({ String(data: $0, encoding: .utf8) }),
                       input)
    }
    func testDefaultProviderInterceptionFactory() {
        let input = UUID().uuidString
        let procedure = self.defaultProviderConfiguration.interceptionProcedure()
        self.run(procedure: procedure, withInput: input)
        XCTAssertEqual(procedure.output.success as? String, input)
    }
    func testDefaultProviderResponseMappingFactory() {
        do {
            _ = try defaultProviderConfiguration.responseMappingProcedure()
        } catch let error {
            XCTAssertEqual(error as? MockResponseMappingProcedureFactory.Error,
                           MockResponseMappingProcedureFactory.error)
        }
    }
    
    private func run<P: Procedure, I>(procedure: P, withInput input: I) where P: InputProcedure, P.Input == I {
        procedure.input = .ready(input)
        self.run(procedure: procedure)
    }
    
    private func run(procedure: Procedure) {
        let expectation = self.expectation(description: "Procedure")
        procedure.addDidFinishBlockObserver {_, _ in
            expectation.fulfill()
        }
        ProcedureQueue.main.addOperation(procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
}

extension FactoriesBasedEndpointProcedureConfigurationProviderTests {
    struct MockRequestProcedureFactory: HTTPRequestProcedureFactory {
        enum Error: Swift.Error {
            case error
        }
        static let error = Error.error
        func requestProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData> {
            throw MockRequestProcedureFactory.error
        }
    }
    
    struct MockResponseMappingProcedureFactory: ResponseMappingProcedureFactory {
        enum Error: Swift.Error {
            case error
        }
        static let error = Error.error
        func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
            throw MockResponseMappingProcedureFactory.error
        }
    }
}
