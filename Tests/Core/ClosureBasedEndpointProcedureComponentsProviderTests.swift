//
//  ClosureBasedEndpointProcedureComponentsProviderTests.swift
//  EndpointProcedureTests
//
//  Created by Sviatoslav Yakymiv on 5/11/19.
//

import XCTest
import EndpointProcedure
import ProcedureKit

class ClosureBasedEndpointProcedureComponentsProviderTests: XCTestCase {
    enum Error: Swift.Error {
        case request
        case validation
        case deserialization
        case interception
        case responseMapping
    }
    
    private let requestProcedure: () -> AnyOutputProcedure<HTTPResponseData> = {
        AnyOutputProcedure(ClosureBasedEndpointProcedureComponentsProviderTests.procedure(withError: .request,
                                                                                          initialValue: ()))
    }
    
    private let validationProcedure: () -> AnyInputProcedure<HTTPResponseData> = {
        let data = HTTPResponseData(urlResponse: nil, data: Data())
        let transform: TransformProcedure<HTTPResponseData, Void> = ClosureBasedEndpointProcedureComponentsProviderTests
            .procedure(withError: .validation, initialValue: data)
        return AnyInputProcedure(transform)
    }
    
    private let deserializationProcedure: () -> AnyProcedure<Data, Any> = {
        let transform: TransformProcedure<Data, Any> = ClosureBasedEndpointProcedureComponentsProviderTests
            .procedure(withError: .deserialization, initialValue: Data())
        return AnyProcedure(transform)
    }
    
    private let interceptionProcedure: () -> AnyProcedure<Any, Any> = {
        let transform: TransformProcedure<Any, Any> = ClosureBasedEndpointProcedureComponentsProviderTests
            .procedure(withError: .interception, initialValue: Data())
        return AnyProcedure(transform)
    }
    
    private let responseMappingProcedure: () -> AnyProcedure<Any, Void> = {
        let transform: TransformProcedure<Any, Void> = ClosureBasedEndpointProcedureComponentsProviderTests
            .procedure(withError: .responseMapping, initialValue: Data())
        return AnyProcedure(transform)
    }
    
    private let defaultValuesProvider: ClosureBasedEndpointProcedureComponentsProvider<Void>
        = ClosureBasedEndpointProcedureComponentsProvider<Void>(
            request: try { throw Error.request }(),
            responseMapping: try { throw Error.responseMapping }()
    )
    
    private lazy var customValuesProvider: ClosureBasedEndpointProcedureComponentsProvider<Void>
        = ClosureBasedEndpointProcedureComponentsProvider<Void>(
            request: self.requestProcedure(),
            validation: self.validationProcedure(),
            deserialization: self.deserializationProcedure(),
            interception: self.interceptionProcedure(),
            responseMapping: self.responseMappingProcedure()
    )
    
    private static func procedure<I, O>(withError error: Error, initialValue: I) -> TransformProcedure<I, O> {
        let procedure = TransformProcedure<I, O>(transform: {_ in throw error })
        procedure.input = .ready(initialValue)
        return procedure
    }
    
    private func run(procedure: Procedure) {
        let expectation = self.expectation(description: "Procedure")
        procedure.addDidFinishBlockObserver {_, _ in
            expectation.fulfill()
        }
        ProcedureQueue.main.addOperation(procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    //MARK: Default provider
    func testDefaultProviderRequestProcedure() {
        do {
            _ = try self.defaultValuesProvider.requestProcedure()
        } catch let error {
            XCTAssertEqual(error as? Error, .request)
        }
    }
    
    func testDefaultProviderValidationProcedure() {
        let procedure = self.defaultValuesProvider.validationProcedure()
        procedure.input = .ready(HTTPResponseData(urlResponse: nil, data: Data()))
        self.run(procedure: procedure)
        XCTAssertNil(procedure.error)
    }
    
    func testDefaultProviderDeserializationProcedure() {
        let input = UUID().uuidString
        let procedure = self.defaultValuesProvider.deserializationProcedure()
        procedure.input = .ready(input.data(using: .utf8)!)
        self.run(procedure: procedure)
        XCTAssertEqual(procedure.output.success.flatMap({ $0 as? Data }).flatMap({ String(data: $0, encoding: .utf8) }),
                       input)
    }
    
    func testDefaultProviderInterceptionProcedure() {
        let input = UUID().uuidString
        let procedure = self.defaultValuesProvider.interceptionProcedure()
        procedure.input = .ready(input)
        self.run(procedure: procedure)
        XCTAssertEqual(procedure.output.success as? String, input)
    }
    
    func testDefaultProviderResponseMappingProcedure() {
        do {
            _ = try self.defaultValuesProvider.responseMappingProcedure()
        } catch let error {
            XCTAssertEqual(error as? Error, .responseMapping)
        }
    }
    
    //MARK: Custom provider
    func testCustomProviderRequestProcedure() throws {
        let procedure = try self.customValuesProvider.requestProcedure()
        self.run(procedure: procedure)
        XCTAssertEqual(procedure.error as? Error, .request)
    }
    
    func testCustomProviderValidationProcedure() {
        let procedure = self.customValuesProvider.validationProcedure()
        self.run(procedure: procedure)
        XCTAssertEqual(procedure.error as? Error, .validation)
    }
    
    func testCustomProviderDeserializationProcedure() {
        let procedure = self.customValuesProvider.deserializationProcedure()
        self.run(procedure: procedure)
        XCTAssertEqual(procedure.error as? Error, .deserialization)
    }
    
    func testCustomProviderInterceptionProcedure() {
        let procedure = self.customValuesProvider.interceptionProcedure()
        self.run(procedure: procedure)
        XCTAssertEqual(procedure.error as? Error, .interception)
    }
    
    func testCustomProviderResponseMappingProcedure() throws {
        let procedure = try self.customValuesProvider.responseMappingProcedure()
        self.run(procedure: procedure)
        XCTAssertEqual(procedure.error as? Error, .responseMapping)
    }
}
