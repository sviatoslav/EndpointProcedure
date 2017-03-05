//
//  AlamofireProcedureFactoryTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/20/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
import SwiftyJSON
import Alamofire
import EndpointProcedure
@testable import AlamofireProcedureFactory

class AlamofireProcedureFactoryTests: XCTestCase {

    fileprivate let baseURL = URL(string: "https://httpbin.org")!

    fileprivate var params: HTTPRequestData.Parameters = ["sKey": "sValue", "iKey": 1]
    fileprivate var headers: HTTPRequestData.HeaderFields = ["hKey": "hValue"]

    //MARK: - Session manager tests
    func testDefaultSessionManager() {
        let data = HTTPRequestData.Builder.for(baseURL.appendingPathComponent("get")).build()
        let factory = AlamofireProcedureFactory()
        do {
            let procedure = try factory.dataLoadingProcedure(with: data)
            let expectation = self.expectation(description: "")
            procedure.addDidFinishBlockObserver {_ in
                expectation.fulfill()
            }
            procedure.enqueue()
            self.waitForExpectations(timeout: 60, handler: nil)
            if let error = procedure.output.error, self.isNoInteretConnection(error: error) {
                return
            }
            let responseHeaders = JSON(data: procedure.output.success!.data)["headers"]
                .dictionaryObject as! [String: String]
            var requestHeaders = SessionManager.defaultHTTPHeaders
            ["Host", "Accept", "Accept-Language", "UserAgent", "Accept-Encoding"].forEach {
                if requestHeaders[$0] == nil {
                    requestHeaders[$0] = responseHeaders[$0]
                }
            }
            XCTAssertEqual(requestHeaders, responseHeaders)
        } catch {
            XCTFail()
        }
    }

    func testCustomSessionManager() {
        let data = HTTPRequestData.Builder.for(baseURL.appendingPathComponent("get")).build()
        let configuration = URLSessionConfiguration.default
        let headers = ["H": "h"]
        configuration.httpAdditionalHeaders = headers
        configuration.timeoutIntervalForRequest = 5
        let sessionManager = SessionManager(configuration: configuration)
        let factory = AlamofireProcedureFactory(sessionManager: sessionManager)
        do {
            let procedure = try factory.dataLoadingProcedure(with: data)
            let expectation = self.expectation(description: "")
            procedure.addDidFinishBlockObserver {_ in
                expectation.fulfill()
            }
            procedure.enqueue()
            self.waitForExpectations(timeout: 60, handler: nil)
            if let error = procedure.output.error, self.isNoInteretConnection(error: error) {
                return
            }
            let responseHeaders = JSON(data: procedure.output.success!.data)["headers"]
                .dictionaryObject as! [String: String]
            var requestHeaders = headers
            ["Host", "Accept", "Accept-Language", "User-Agent", "Accept-Encoding"].forEach {
                if requestHeaders[$0] == nil {
                    requestHeaders[$0] = responseHeaders[$0]
                }
            }
            XCTAssertEqual(requestHeaders, responseHeaders)
        } catch {
            XCTFail()
        }
    }

    //MARK: - URL encoding tests
    func testGETWithURLEncoding() {
        self.testRequest(forPath: "get", encoding: .url, method: .get) {
            let url = URL(string: $0["url"].stringValue)!
            self.assert(urlEncodingParameters: self.queryParameters(from: url))
        }
    }

    func testPOSTWithURLEncoding() {
        self.testRequest(forPath: "post", encoding: .url, method: .post) {
            self.assert(urlEncodingParameters: $0["form"].dictionaryValue)
        }
    }

    func testPUTWithURLEncoding() {
        self.testRequest(forPath: "put", encoding: .url, method: .put) {
            self.assert(urlEncodingParameters: $0["form"].dictionaryValue)
        }
    }

    func testDELETEWithURLEncoding() {
        self.testRequest(forPath: "delete", encoding: .url, method: .delete) {
            let url = URL(string: $0["url"].stringValue)!
            self.assert(urlEncodingParameters: self.queryParameters(from: url))
        }
    }

    //MARK: - JSON encoding tests
    func testGETWithJSONEncoding() {
        self.testRequest(forPath: "get", encoding: .json, method: .get) {
            let url = URL(string: $0["url"].stringValue)!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    func testPOSTWithJSONEncoding() {
        self.testRequest(forPath: "post", encoding: .json, method: .post) {
            self.assert(parametersJSON: $0["data"].stringValue)
        }
    }

    func testPUTWithJSONEncoding() {
        self.testRequest(forPath: "put", encoding: .json, method: .put) {
            self.assert(parametersJSON: $0["data"].stringValue)
        }
    }

    func testDELETEWithJSONEncoding() {
        self.testRequest(forPath: "delete", encoding: .json, method: .delete) {
            let url = URL(string: $0["url"].stringValue)!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    //MARK: - XML plist encoding tests
    func testGETWithPlistXMLEncoding() {
        self.testRequest(forPath: "get", encoding: .plist(option: .xml), method: .get) {
            let url = URL(string: $0["url"].stringValue)!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    func testPOSTWithPlistXMLEncoding() {
        self.testRequest(forPath: "post", encoding: .plist(option: .xml), method: .post) {
            let xml = $0["data"].stringValue
            let xmlData = xml.data(using: .utf8)!
            let plist = try! PropertyListSerialization.propertyList(from: xmlData, format: nil)
            self.assert(parameters: plist as! HTTPRequestData.Parameters)
        }
    }

    func testPUTWithPlistXMLEncoding() {
        self.testRequest(forPath: "put", encoding: .plist(option: .xml), method: .put) {
            let xml = $0["data"].stringValue
            let xmlData = xml.data(using: .utf8)!
            let plist = try! PropertyListSerialization.propertyList(from: xmlData, format: nil)
            self.assert(parameters: plist as! HTTPRequestData.Parameters)
        }
    }

    func testDELETEWithPlistXMLEncoding() {
        self.testRequest(forPath: "delete", encoding: .plist(option: .xml), method: .delete) {
            let url = URL(string: $0["url"].stringValue)!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    //MARK: - Binary plist encoding tests
    func testGETWithPlistBinaryEncoding() {
        self.testRequest(forPath: "get", encoding: .plist(option: .binary), method: .get) {
            let url = URL(string: $0["url"].stringValue)!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    func testPOSTWithPlistBinaryEncoding() {
        self.testRequest(forPath: "post", encoding: .plist(option: .binary), method: .post) {
            let url = URL(string: $0["data"].stringValue)!
            let data = try! Data(contentsOf: url)
            let plist = try! PropertyListSerialization.propertyList(from: data, format: nil)
            self.assert(parameters: plist as! HTTPRequestData.Parameters)
        }
    }

    func testPUTWithPlistBinaryEncoding() {
        self.testRequest(forPath: "put", encoding: .plist(option: .binary), method: .put) {
            let url = URL(string: $0["data"].stringValue)!
            let data = try! Data(contentsOf: url)
            let plist = try! PropertyListSerialization.propertyList(from: data, format: nil)
            self.assert(parameters: plist as! HTTPRequestData.Parameters)
        }
    }

    func testDELETEWithPlistBinaryEncoding() {
        self.testRequest(forPath: "delete", encoding: .plist(option: .binary), method: .delete) {
            let url = URL(string: $0["url"].stringValue)!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

}

fileprivate extension AlamofireProcedureFactoryTests {
    //MARK: - Helpers
    fileprivate func configure(builder: HTTPRequestData.Builder) -> HTTPRequestData.Builder {
        return builder.appending(parameters: params).appending(headerFields: headers)
    }

    fileprivate func json(for path: String, withEncoding encoding: HTTPRequestData.ParameterEncoding,
                      method: HTTPRequestData.Method) throws -> JSON {
        let url = self.baseURL.appendingPathComponent(path)
        let builder = try HTTPRequestData.Builder.for(url).with(method: method).with(parameterEncoding: encoding)
        let data = self.configure(builder: builder).build()
        let expectation = self.expectation(description: "Procedure expectation")
        let procedure = try AlamofireProcedureFactory().dataLoadingProcedure(with: data)
        procedure.addCompletionBlock {
            expectation.fulfill()
        }
        procedure.enqueue()
        waitForExpectations(timeout: 60, handler: nil)
        let error = procedure.output.error
        guard error == nil else {
            throw error!
        }
        return JSON(data: procedure.output.success!.data)
    }

    fileprivate func isNoInteretConnection(error: Error?) -> Bool {
        return (error as? NSError)?.code == -1009 || (error as? NSError)?.code == -1004
            || (error as? NSError)?.code == -1001
    }

    fileprivate func isEqual<T: Equatable>(type: T.Type, a: Any, b: Any) -> Bool {
        guard let a = a as? T, let b = b as? T else { return false }

        return a == b
    }

    fileprivate func assert(parametersJSON: String) {
        let args = JSON(data: parametersJSON.data(using: .utf8)!).dictionaryObject!
        self.assert(parameters: args)
    }

    fileprivate func assert(parameters args: HTTPRequestData.Parameters) {
        XCTAssertEqual(self.params.count, args.count)
        var parameters: HTTPRequestData.Parameters = [:]
        params.forEach {
            if let object = args[$0.key] {
                parameters[$0.key] = object
            } else {
                XCTFail()
            }
        }
        XCTAssert(NSDictionary(dictionary: self.params).isEqual(to: parameters))
    }

    fileprivate func queryParameters(from url: URL) -> [String: String] {
        return url.query.map { (query: String) -> [String : String] in
            var parameters: [String: String] = [:]
            query.components(separatedBy: "&").forEach {
                let components = $0.components(separatedBy: "=")
                XCTAssertEqual(components.count, 2)
                parameters[components[0]] = components[1]
            }
            return parameters
            } ?? [:]
    }

    fileprivate func assert(urlEncodingParameters: [String: String]) {
        XCTAssertEqual(urlEncodingParameters.count, self.params.count)
        urlEncodingParameters.forEach {
            XCTAssertNotNil(self.params[$0.key])
            XCTAssertEqual("\(self.params[$0.key]!)", $0.value)
        }
    }


    fileprivate func assert(urlEncodingParameters: [String: JSON]) {
        XCTAssertEqual(urlEncodingParameters.count, self.params.count)
        urlEncodingParameters.forEach {
            XCTAssertNotNil(self.params[$0.key])
            XCTAssertEqual("\(self.params[$0.key]!)", $0.value.stringValue)
        }
    }

    fileprivate func assert(headers: [String: JSON]) {
        self.headers.forEach { (key, value) in
            let values = headers.flatMap {
                return key.caseInsensitiveCompare($0.key) == .orderedSame ? $0.value.stringValue : nil
            }
            XCTAssertEqual(values.count, 1)
            XCTAssertEqual(value.caseInsensitiveCompare(values[0]), .orderedSame)
        }
    }

    fileprivate func testRequest(forPath path: String, encoding: HTTPRequestData.ParameterEncoding,
                             method: HTTPRequestData.Method, testingClosure: (JSON) -> Void) {
        do {
            let json = try self.json(for: path, withEncoding: encoding, method: method)
            self.assert(headers: json["headers"].dictionaryValue)
            testingClosure(json)
        } catch let e {
            if !self.isNoInteretConnection(error: e) {
                XCTFail("\(e)")
            }
        }
    }
}
