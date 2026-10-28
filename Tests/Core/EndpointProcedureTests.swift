//
//  EndpointProcedureTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 1/5/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import ProcedureKit
@testable import EndpointProcedure

class EndpointProcedureTests: XCTestCase {

    enum Error: Swift.Error {
        case value
    }

    func testWithoutOverloads() {
        class Procedure: EndpointProcedure<Void> {}
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(EndpointProcedureError.missingDataLoadingProcedure, result.error as? EndpointProcedureError)
    }

    func testNonForwardingDataFlowErrorReachesEndpointBeforeCompletion() {
        class NonForwardingFlow: DataFlowProcedure<Void> {
            override func procedureWillFinish(with error: Swift.Error?) {}
        }
        class Procedure: EndpointProcedure<Void> {
            override func dataFlowProcedure() throws -> DataFlowProcedure<Void> {
                let loading = TransformProcedure<Void, Data> {
                    throw ProcedureKitError.dependency(finishedWithError: URLError(.notConnectedToInternet))
                }
                loading.input = pendingVoid
                return NonForwardingFlow(dataLoadingProcedure: loading,
                    deserializationProcedure: TransformProcedure<Data, Any> { $0 },
                    resultMappingProcedure: TransformProcedure<Any, Void> { _ in })
            }
        }
        let procedure = Procedure()
        let willFinish = expectation(description: "Endpoint publishes the underlying error before completion")
        let didFinish = expectation(description: "Endpoint preserves the error after completion")
        procedure.addWillFinishBlockObserver { procedure, _, _ in
            XCTAssertEqual((procedure.output.error as? URLError)?.code, .notConnectedToInternet)
            willFinish.fulfill()
        }
        procedure.addDidFinishBlockObserver { procedure, _ in
            XCTAssertEqual((procedure.output.error as? URLError)?.code, .notConnectedToInternet)
            didFinish.fulfill()
        }
        ProcedureQueue().addOperation(procedure)
        wait(for: [willFinish, didFinish], timeout: 2, enforceOrder: true)
    }

    func testDataLoadingProcedureInitializationFailure() {
        class Procedure: EndpointProcedure<Void> {
            override func dataLoadingProcedure() throws -> AnyOutputProcedure<Data> { throw Error.value }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(Error.value, result.error as? Error)
    }
    func testHTTPDataLoadingProcedureInitializationFailure() {
        class Procedure: EndpointProcedure<Void> {
            override func requestProcedure() throws -> AnyOutputProcedure<HTTPResponseData> {
                throw Error.value
            }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(Error.value, result.error as? Error)
    }
    func testMissingMappingProcedure() {
        class Procedure: EndpointProcedure<Void> {
            override func dataLoadingProcedure() throws -> AnyOutputProcedure<Data> {
                let procedure = TransformProcedure<Void, Data> { return Data() }
                procedure.input = pendingVoid
                return AnyOutputProcedure(procedure)
            }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(EndpointProcedureError.missingMappingProcedure, result.error as? EndpointProcedureError)
    }
    func testMappingProcedureInitializationFailure() {
        class Procedure: EndpointProcedure<Void> {
            override func dataLoadingProcedure() throws -> AnyOutputProcedure<Data> {
                let procedure = TransformProcedure<Void, Data> { return Data() }
                procedure.input = pendingVoid
                return AnyOutputProcedure(procedure)
            }
            override func responseMappingProcedure() throws -> AnyProcedure<Any, Void> {
                throw Error.value
            }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(Error.value, result.error as? Error)
    }
    func testDataFlowProcedureInitializationFailure() {
        class Procedure: EndpointProcedure<Void> {
            override func dataFlowProcedure() throws -> DataFlowProcedure<Void> { throw Error.value }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(Error.value, result.error as? Error)
    }
    func testValidationProcedureFailure() {
        class Procedure: EndpointProcedure<Void> {
            override func requestProcedure() throws -> AnyOutputProcedure<HTTPResponseData> {
                let procedure = TransformProcedure<Void, HTTPResponseData> {
                    return HTTPResponseData(urlResponse: nil, data: Data())
                }
                procedure.input = pendingVoid
                return AnyOutputProcedure(procedure)
            }
            override func validationProcedure() -> AnyInputProcedure<HTTPResponseData> {
                return AnyInputProcedure(TransformProcedure<HTTPResponseData, Void> {_ in throw Error.value })
            }
            override func responseMappingProcedure() throws -> AnyProcedure<Any, Void> {
                return AnyProcedure(TransformProcedure<Any, Void>{_ in})
            }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(Error.value, result.error as? Error)
    }
    func testInterceptionProcedureFailure() {
        class Procedure: EndpointProcedure<Void> {
            override func requestProcedure() throws -> AnyOutputProcedure<HTTPResponseData> {
                let procedure = TransformProcedure<Void, HTTPResponseData> {
                    return HTTPResponseData(urlResponse: nil, data: Data())
                }
                procedure.input = pendingVoid
                return AnyOutputProcedure(procedure)
            }
            override func interceptionProcedure() -> AnyProcedure<Any, Any> {
                return AnyProcedure(TransformProcedure<Any, Any> {_ in throw Error.value })
            }
            override func responseMappingProcedure() throws -> AnyProcedure<Any, Void> {
                return AnyProcedure(TransformProcedure<Any, Void>{_ in})
            }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(Error.value, result.error as? Error)
    }
    func testConfigurationProvider() {
        struct LoadingFactory: HTTPRequestProcedureFactory {
            func requestProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData> {
                let transform = TransformProcedure<Void, HTTPResponseData> {
                    let data = try! JSONSerialization.data(withJSONObject: [1, 2, 3, 4], options: [])
                    return HTTPResponseData(urlResponse: nil, data: data)
                }
                transform.input = pendingVoid
                return AnyOutputProcedure(transform)
            }
        }
        struct DeserializationFactory: DataDeserializationProcedureFactory {
            func dataDeserializationProcedure() -> AnyProcedure<Data, Any> {
                return AnyProcedure(TransformProcedure<Data, Any> {
                    return try JSONSerialization.jsonObject(with: $0, options: [])
                })
            }
        }
        struct MappingFactory: ResponseMappingProcedureFactory {
            func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
                return AnyProcedure(TransformProcedure<Any, T> { return ($0 as! [Int]).reduce(0, +) as! T })
            }
        }
        class Procedure: EndpointProcedure<Int>, ConfigurationProviderContaining, HTTPRequestDataContaining {
            let configurationProvider: EndpointProcedureConfigurationProviding
                = FactoriesBasedEndpointProcedureConfigurationProvider(
                    request: LoadingFactory(),
                    deserialization: DeserializationFactory(),
                    responseMapping: MappingFactory()
            )
            func requestData() throws -> HTTPRequestData {
                return HTTPRequestData.Builder.for(URL(string: "http://g")!).build()
            }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(10, result.success)
    }
    func testSettingCustomConfiguration() {
        struct LoadingFactory: HTTPRequestProcedureFactory {
            func requestProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData> {
                let transform = TransformProcedure<Void, HTTPResponseData> {
                    let data = try! JSONSerialization.data(withJSONObject: [1, 2, 3, 4], options: [])
                    return HTTPResponseData(urlResponse: nil, data: data)
                }
                transform.input = pendingVoid
                return AnyOutputProcedure(transform)
            }
        }
        struct DeserializationFactory: DataDeserializationProcedureFactory {
            func dataDeserializationProcedure() -> AnyProcedure<Data, Any> {
                return AnyProcedure(TransformProcedure<Data, Any> {
                    return try JSONSerialization.jsonObject(with: $0, options: [])
                })
            }
        }
        struct MappingFactory: ResponseMappingProcedureFactory {
            func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
                return AnyProcedure(TransformProcedure<Any, T> { return ($0 as! [Int]).reduce(0, +) as! T })
            }
        }
        class Procedure: EndpointProcedure<Int> {
            override init() {
                super.init()
                self.configuration = ClosureBasedEndpointProcedureComponentsProvider(
                    request: try LoadingFactory().requestProcedure(with: self.requestData()),
                    deserialization: DeserializationFactory().dataDeserializationProcedure(),
                    responseMapping: try MappingFactory().responseMappingProcedure(for: Int.self)
                ).wrapped
            }
            func requestData() throws -> HTTPRequestData {
                return HTTPRequestData.Builder.for(URL(string: "http://g")!).build()
            }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(10, result.success)
    }
    func testRequestDataException() {
        struct LoadingFactory: HTTPRequestProcedureFactory {
            func requestProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData> {
                let transform = TransformProcedure<Void, HTTPResponseData> {
                    let data = try! JSONSerialization.data(withJSONObject: [1, 2, 3, 4], options: [])
                    return HTTPResponseData(urlResponse: nil, data: data)
                }
                transform.input = pendingVoid
                return AnyOutputProcedure(transform)
            }
        }
        struct DeserializationFactory: DataDeserializationProcedureFactory {
            func dataDeserializationProcedure() -> AnyProcedure<Data, Any> {
                return AnyProcedure(TransformProcedure<Data, Any> {
                    return try JSONSerialization.jsonObject(with: $0, options: [])
                })
            }
        }
        struct MappingFactory: ResponseMappingProcedureFactory {
            func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
                return AnyProcedure(TransformProcedure<Any, T> { return ($0 as! [Int]).reduce(0, +) as! T })
            }
        }
        class Procedure: EndpointProcedure<Int>, ConfigurationProviderContaining, HTTPRequestDataContaining {
            enum Error: Swift.Error {
                case requestData
            }
            let configurationProvider: EndpointProcedureConfigurationProviding
                = FactoriesBasedEndpointProcedureConfigurationProvider(
                    request: LoadingFactory(),
                    deserialization: DeserializationFactory(),
                    responseMapping: MappingFactory()
            )
            func requestData() throws -> HTTPRequestData {
                throw Error.requestData
            }
        }
        let result = self.procedureResult(for: Procedure())
        XCTAssertEqual(Procedure.Error.requestData, result.error as? Procedure.Error)
    }
}

extension EndpointProcedureTests {
    fileprivate func procedureResult<T>(for procedure: EndpointProcedure<T>) -> Pending<ProcedureResult<T>> {
        let expectation = self.expectation(description: "Output is available before completion")
        var result: Pending<ProcedureResult<T>> = .pending
        procedure.addWillFinishBlockObserver { procedure, _, _ in
            result = procedure.output
            expectation.fulfill()
        }
        ProcedureQueue().addOperation(procedure)
        self.waitForExpectations(timeout: 1, handler: nil)
        return result
    }
}
