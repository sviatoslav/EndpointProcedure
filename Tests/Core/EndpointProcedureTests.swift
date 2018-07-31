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

    private let requestData = HTTPRequestData.Builder.for(URL(string: "https://my.api")!)
                                                    .appending(parameterValue: "pV", for: "pK")
                                                    .appending(headerFieldValue: "hV", for: "hK").build()

    override func setUp() {
        super.setUp()
        let jsonDeserializationProcedureFactory = AnyDataDeserializationProcedureFactory {
            try JSONSerialization.jsonObject(with: $0, options: [])
        }
        HTTPRequestData.Builder.baseURL = URL(string: "https://my.api")!
        let config = Configuration(dataLoadingProcedureFactory: HTTPDataLoadingProcedureMockFactory(),
                                   dataDeserializationProcedureFactory: jsonDeserializationProcedureFactory,
                                   responseMappingProcedureFactory: OptionalCastResponseMappingProcedureFactory())
        Configuration.default = config
    }

    func testDataLoadingProcedureInitializationWithoutConfiguration() {
        Configuration.default = nil
        let procedure = EndpointProcedure<[String: String]>(dataLoadingProcedure: DataLoadingProcedureMock())
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error.map { "\($0)" }, "\(EndpointProcedureError.missingConfiguration)")
    }

    func testRequestDataInitializationWithoutConfiguration() {
        Configuration.default = nil
        let procedure = EndpointProcedure<[String: String]>(requestData: self.requestData)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error.map { "\($0)" }, "\(EndpointProcedureError.missingConfiguration)")
    }

    func testCustomConfiguration() {
        let config = Configuration.default
        Configuration.default = nil
        let dictionary = ["Key": "Value"]
        let procedure = EndpointProcedure<[String: String]>(dataLoadingProcedure:
            DataLoadingProcedureMock(dictionary: dictionary), configuration: config)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.success ?? ["":""], dictionary)
    }

    func testConfigurationsPriority() {
        XCTAssertNil(Configuration.self as? AnyClass, "Need to rewrite test")
        var config = Configuration.default!
        config.dataLoadingProcedureFactory = FailableHTTPDataLoadingProcedureMockFactory()
        let procedure = EndpointProcedure<[String: String]>(requestData: self.requestData, configuration: config)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error as NSError?, FailableHTTPDataLoadingProcedureMockFactory.error)
    }

    func testInitWithDataLoadingProcedure() {
        let procedure = EndpointProcedure<[String: String]>(dataLoadingProcedure: DataLoadingProcedureMock())
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.success ?? [:], DataLoadingProcedureMock.defaultDictionary)
    }

    func testInitWithHTTPData() {
        let procedure = EndpointProcedure<[AnyHashable: Any]>(requestData: self.requestData)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(NSDictionary(dictionary: result.success ?? [:]),
                       NSDictionary(dictionary: HTTPDataLoadingProcedureMock.dictinary(for: self.requestData)))
    }

    func testAllProceduresNotEmpty() {
        let interceptor = TransformProcedure<Any, Any> {
            var dict = $0 as! [String: Any]
            dict["newKey"] = "newValue"
            return dict
        }
        let procedure = EndpointProcedure<[AnyHashable: Any]>(requestData: self.requestData,
                                                              interceptionProcedure: interceptor)
        let result = self.procedureResult(for: procedure)
        var expectedResultDict = HTTPDataLoadingProcedureMock.dictinary(for: self.requestData)
        expectedResultDict["newKey"] = "newValue"
        XCTAssertEqual(NSDictionary(dictionary: result.success ?? [:]),
                       NSDictionary(dictionary: expectedResultDict))
    }

    func testFailureInDataLoadingProcedure() {
        let procedure = EndpointProcedure<[String: String]>(dataLoadingProcedure:
                                        DataLoadingProcedureMock(dictionary: ["url": URL(string: "https://my.api")!]))
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error as NSError?, DataLoadingProcedureMock.jsonSerializationError)
    }

    func testFailureInHTTPDataLoadingProcedure() {
        let requestData = HTTPRequestData.Builder.for(self.requestData.url)
            .appending(parameters: ["url": self.requestData.url]).build()
        let procedure = EndpointProcedure<[AnyHashable: Any]>(requestData: requestData)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error as NSError?, HTTPDataLoadingProcedureMock.jsonSerializationError)
    }

    func testFailureInResponseValidationProcedure() {
        let error = NSError(domain: "ResponseValidatorProcedureDomain", code: 1, userInfo: nil)
        let validator = TransformProcedure<HTTPResponseData, Void> {_ in
            throw error
        }
        let procedure = EndpointProcedure<[AnyHashable: Any]>(requestData: self.requestData,
                                                              validationProcedure: validator)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error as NSError?, error)
    }

    func testFailureInResponseInterceptorProcedure() {
        let error = NSError(domain: "ResponseInterceptorProcedureDomain", code: 1, userInfo: nil)
        let interceptor = TransformProcedure<Any, Any> {_ in
            throw error
        }
        let procedure = EndpointProcedure<[AnyHashable: Any]>(requestData: self.requestData,
                                                              interceptionProcedure: interceptor)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error as NSError?, error)
    }

    func testFailureInResponseMappingProcedure() {
        let procedure = EndpointProcedure<String>(requestData: self.requestData)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error as NSError?, OptionalCastResponseMappingProcedure<Any>.castFailedError)
    }

    func testDataLoadingProcedureFactoryFailure() {
        var configuration = Configuration.default
        configuration?.dataLoadingProcedureFactory = FailableHTTPDataLoadingProcedureMockFactory()
        let procedure = EndpointProcedure<String>(requestData: self.requestData, configuration: configuration)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error as NSError?, FailableHTTPDataLoadingProcedureMockFactory.error)
    }

    func testResponseMappingProcedureFactory() {
        var configuration = Configuration.default
        configuration?.responseMappingProcedureFactory = FailableResponseMappingProcedureFactory()
        let procedure = EndpointProcedure<String>(requestData: self.requestData, configuration: configuration)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error as NSError?, FailableResponseMappingProcedureFactory.error)
    }

    func testCustomDataFlowProcedure() {
        let dataFlowProcedure = DataFlowProcedureMock()
        let procedure = EndpointProcedure<Int>(dataFlowProcedure: dataFlowProcedure)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.success, 1)
    }

    func testPendingAfterCompletion() {
        let dataFlowProcedure = DataFlowProcedureMock()
        dataFlowProcedure.addWillFinishBlockObserver {
            $0.0.output = .pending
        }
        let procedure = EndpointProcedure<Int>(dataFlowProcedure: dataFlowProcedure)
        let result = self.procedureResult(for: procedure)
        XCTAssertEqual(result.error.map { "\($0)" }, "\(EndpointProcedureError.pendingOutputAfterCompletion)")
    }

    func testOutputIsReadOnly() {
        let procedure = EndpointProcedure<String>(requestData: self.requestData)
        _ = self.procedureResult(for: procedure)
        procedure.output = .ready(.success(""))
        XCTAssertEqual(procedure.output.error as NSError?, OptionalCastResponseMappingProcedure<Any>.castFailedError)
    }
}

extension EndpointProcedureTests {
    fileprivate func procedureResult<T>(for procedure: EndpointProcedure<T>) -> Pending<ProcedureResult<T>> {
        let expectation = self.expectation(description: "")
        procedure.addDidFinishBlockObserver {_ in
            expectation.fulfill()
        }
        procedure.enqueue()
        self.waitForExpectations(timeout: 1, handler: nil)
        return procedure.output
    }
}

fileprivate class DataFlowProcedureMock: DataFlowProcedure<Int> {
    init() {
        let dataLoadingProcedure = TransformProcedure<Void, Data> { return Data() }
        dataLoadingProcedure.input = pendingVoid
        let deserializationProcedure = TransformProcedure<Data, Any> { return $0 }
        let mappingProcedure = TransformProcedure<Any, Int> {_ in return 1 }
        super.init(dataLoadingProcedure: dataLoadingProcedure, deserializationProcedure: deserializationProcedure,
                   interceptionProcedure: DataFlowProcedure<Int>.createEmptyInterceptionProcedure(),
                   resultMappingProcedure: mappingProcedure)
    }
}

fileprivate class OptionalCastResponseMappingProcedure<T>: Procedure, OutputProcedure, InputProcedure {

    var output: Pending<ProcedureResult<T>> = .pending
    var input: Pending<Any> = .pending

    class var castFailedError: NSError {
        return NSError(domain: "OptionalCastResponseMappingProcedureDomain", code: 1, userInfo: nil)
    }

    fileprivate override func execute() {
        guard let result = self.input.value as? T else {
            self.finish(withResult: .failure(OptionalCastResponseMappingProcedure.castFailedError))
            return
        }
        self.finish(withResult: .success(result))
    }
}

fileprivate class OptionalCastResponseMappingProcedureFactory: ResponseMappingProcedureFactory {
    fileprivate func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
        return AnyProcedure(OptionalCastResponseMappingProcedure<T>())
    }
}

fileprivate class FailableResponseMappingProcedureFactory: ResponseMappingProcedureFactory {
    class var error: NSError {
        return NSError(domain: "FailableResponseMappingProcedureFactoryDomail", code: 1, userInfo: nil)
    }
    fileprivate func responseMappingProcedure<T>(for type: T.Type) throws -> AnyProcedure<Any, T> {
        throw FailableResponseMappingProcedureFactory.error
    }
}

fileprivate class HTTPDataLoadingProcedureMock: Procedure, OutputProcedure {

    var output: Pending<ProcedureResult<HTTPResponseData>> = .pending

    class var jsonSerializationError: NSError {
        return NSError(domain: "HTTPDataLoadingProcedureMockDomail", code: 1, userInfo: nil)
    }

    static func dictinary(for data: HTTPRequestData) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [
            "url": data.url.absoluteString,
            "method": data.method.rawValue
        ]
        _ = data.parameters.map {
            dict["parameters"] = $0
        }
        _ = data.headerFields.map {
            dict["headers"] = $0
        }
        return dict
    }

    private let httpRequestData: HTTPRequestData

    init(httpRequestData: HTTPRequestData) {
        self.httpRequestData = httpRequestData
        super.init()
    }

    fileprivate override func execute() {
        let dict = HTTPDataLoadingProcedureMock.dictinary(for: self.httpRequestData)
        let response = HTTPURLResponse(url: httpRequestData.url, statusCode: 200, httpVersion: "",
                                       headerFields: httpRequestData.headerFields)
        do {
            guard JSONSerialization.isValidJSONObject(dict) else {
                throw HTTPDataLoadingProcedureMock.jsonSerializationError
            }
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            self.finish(withResult: .success(HTTPResponseData(urlResponse: response, data: data)))
        } catch let error {
            self.finish(withResult: .failure(error))
        }
    }
}

fileprivate class HTTPDataLoadingProcedureMockFactory: HTTPDataLoadingProcedureFactory {
    fileprivate func dataLoadingProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData> {
        return AnyOutputProcedure(HTTPDataLoadingProcedureMock(httpRequestData: data))
    }
}

fileprivate class FailableHTTPDataLoadingProcedureMockFactory: HTTPDataLoadingProcedureFactory {

    class var error: NSError {
        return NSError(domain: "FailableHTTPDataLoadingProcedureMockFactoryDomail", code: 1, userInfo: nil)
    }

    fileprivate func dataLoadingProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData> {
        throw FailableHTTPDataLoadingProcedureMockFactory.error
    }
}

fileprivate class DataLoadingProcedureMock: Procedure, OutputProcedure {

    var output: Pending<ProcedureResult<Data>> = .pending

    class var jsonSerializationError: NSError {
        return NSError(domain: "DataLoadingProcedureMockDomail", code: 1, userInfo: nil)
    }

    static let defaultDictionary = ["DataLoadingProcedureMockKey": "DataLoadingProcedureMockValue"]
    private let dict: [AnyHashable: Any]?

    init(dictionary: [AnyHashable: Any]? = nil) {
        self.dict = dictionary
        super.init()
    }

    fileprivate override func execute() {
        do {
            let object: Any = self.dict ?? type(of: self).defaultDictionary
            guard JSONSerialization.isValidJSONObject(object) else {
                throw DataLoadingProcedureMock.jsonSerializationError
            }
            let data = try JSONSerialization.data(withJSONObject: object)
            self.finish(withResult: .success(data))
        } catch let error {
            self.finish(withResult: .failure(error))
        }
    }
}

