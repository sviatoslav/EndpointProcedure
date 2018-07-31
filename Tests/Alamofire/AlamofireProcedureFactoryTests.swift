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

    fileprivate let baseURL = URL(string: "http://httpbin.org")!

    fileprivate var params: HTTPRequestData.Parameters = ["sKey": "sValue", "iKey": 1]
    fileprivate var headers: HTTPRequestData.HeaderFields = ["hKey": "hValue"]

    //MARK: - Session manager tests
    func testDefaultSessionManager() {
        let data = HTTPRequestData.Builder.for(baseURL.appendingPathComponent("get")).build()
        let factory = AlamofireProcedureFactory()
        do {
            let procedure = try factory.dataLoadingProcedure(with: data).children[0] as! AlamofireProcedure
            let configurationHeaders = procedure.request.session.configuration.httpAdditionalHeaders ?? [:]
            SessionManager.defaultHTTPHeaders.forEach {
                XCTAssert((configurationHeaders[$0.key] as? String) == $0.value)
            }
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
            let procedure = try factory.dataLoadingProcedure(with: data).children[0] as! AlamofireProcedure
            let configurationHeaders = procedure.request.session.configuration.httpAdditionalHeaders ?? [:]
            headers.forEach {
                XCTAssert((configurationHeaders[$0.key] as? String) == $0.value)
            }
        } catch {
            XCTFail()
        }
    }

    //MARK: - URL encoding tests
    func testGETWithURLEncoding() {
        self.testRequest(forPath: "get", encoding: .url, method: .get) {
            let url = $0.url!
            self.assert(urlEncodingParameters: self.queryParameters(from: url))
        }
    }

    func testPOSTWithURLEncoding() {
        self.testRequest(forPath: "post", encoding: .url, method: .post) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-www-form-urlencoded"))
            let body = $0.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) ?? ""
            self.assert(urlEncodingParameters: body)
        }
    }

    func testPUTWithURLEncoding() {
        self.testRequest(forPath: "put", encoding: .url, method: .put) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-www-form-urlencoded"))
            let body = $0.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) ?? ""
            self.assert(urlEncodingParameters: body)
        }
    }

    func testDELETEWithURLEncoding() {
        self.testRequest(forPath: "delete", encoding: .url, method: .delete) {
            let url = $0.url!
            self.assert(urlEncodingParameters: self.queryParameters(from: url))
        }
    }

    //MARK: - JSON encoding tests
    func testGETWithJSONEncoding() {
        self.testRequest(forPath: "get", encoding: .json, method: .get) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/json"))
            let url = $0.url!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    func testPOSTWithJSONEncoding() {
        self.testRequest(forPath: "post", encoding: .json, method: .post) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/json"))
            let json = try! JSON(data: $0.httpBody!)
            self.assert(urlEncodingParameters: json.dictionaryValue)
        }
    }

    func testPUTWithJSONEncoding() {
        self.testRequest(forPath: "put", encoding: .json, method: .put) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/json"))
            let json = try! JSON(data: $0.httpBody!)
            self.assert(urlEncodingParameters: json.dictionaryValue)
        }
    }

    func testDELETEWithJSONEncoding() {
        self.testRequest(forPath: "delete", encoding: .json, method: .delete) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/json"))
            let url = $0.url!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    //MARK: - XML plist encoding tests
    func testGETWithPlistXMLEncoding() {
        self.testRequest(forPath: "get", encoding: .plist(option: .xml), method: .get) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-plist"))
            let url = $0.url!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    func testPOSTWithPlistXMLEncoding() {
        self.testRequest(forPath: "post", encoding: .plist(option: .xml), method: .post) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-plist"))
            let plist = try! PropertyListSerialization.propertyList(from: $0.httpBody!, format: nil)
            self.assert(parameters: plist as! HTTPRequestData.Parameters)
        }
    }

    func testPUTWithPlistXMLEncoding() {
        self.testRequest(forPath: "put", encoding: .plist(option: .xml), method: .put) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-plist"))
            let plist = try! PropertyListSerialization.propertyList(from: $0.httpBody!, format: nil)
            self.assert(parameters: plist as! HTTPRequestData.Parameters)
        }
    }

    func testDELETEWithPlistXMLEncoding() {
        self.testRequest(forPath: "delete", encoding: .plist(option: .xml), method: .delete) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-plist"))
            let url = $0.url!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    //MARK: - Binary plist encoding tests
    func testGETWithPlistBinaryEncoding() {
        self.testRequest(forPath: "get", encoding: .plist(option: .binary), method: .get) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-plist"))
            let url = $0.url!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

    func testPOSTWithPlistBinaryEncoding() {
        self.testRequest(forPath: "post", encoding: .plist(option: .binary), method: .post) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-plist"))
            let plist = try! PropertyListSerialization.propertyList(from: $0.httpBody!, format: nil)
            self.assert(parameters: plist as! HTTPRequestData.Parameters)
        }
    }

    func testPUTWithPlistBinaryEncoding() {
        self.testRequest(forPath: "put", encoding: .plist(option: .binary), method: .put) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-plist"))
            let plist = try! PropertyListSerialization.propertyList(from: $0.httpBody!, format: nil)
            self.assert(parameters: plist as! HTTPRequestData.Parameters)
        }
    }

    func testDELETEWithPlistBinaryEncoding() {
        self.testRequest(forPath: "delete", encoding: .plist(option: .binary), method: .delete) {
            XCTAssert($0.allHTTPHeaderFields!["Content-Type"]!.hasPrefix("application/x-plist"))
            let url = $0.url!
            XCTAssert(self.queryParameters(from: url).isEmpty)
        }
    }

}

fileprivate extension AlamofireProcedureFactoryTests {
    //MARK: - Helpers
    fileprivate func configure(builder: HTTPRequestData.Builder) -> HTTPRequestData.Builder {
        return builder.appending(parameters: params).appending(headerFields: headers)
    }

    fileprivate func request(for path: String, withEncoding encoding: HTTPRequestData.ParameterEncoding,
                      method: HTTPRequestData.Method) throws -> URLRequest {
        let url = self.baseURL.appendingPathComponent(path)
        let builder = try HTTPRequestData.Builder.for(url).with(method: method).with(parameterEncoding: encoding)
        let data = self.configure(builder: builder).build()
        let procedure = try AlamofireProcedureFactory().dataLoadingProcedure(with: data)
            .children.first as! AlamofireProcedure
        switch procedure.request.request {
        case let request?: return request
        case nil: throw NSError(domain: "", code: -1, userInfo: nil)
        }
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

    fileprivate func assert(urlEncodingParameters: String) {
        let parameters: [String: String] = urlEncodingParameters.components(separatedBy: "&").reduce([:]) {
            var result = $0
            let keyValue = $1.components(separatedBy: "=")
            result[keyValue[0]] = keyValue[1]
            return result
        }
        self.assert(urlEncodingParameters: parameters)
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

    fileprivate func assert(headers: [String: String]) {
        self.headers.forEach { (key, value) in
            let values = headers.flatMap {
                return key.caseInsensitiveCompare($0.key) == .orderedSame ? $0.value : nil
            }
            XCTAssertEqual(values.count, 1)
            XCTAssertEqual(value.caseInsensitiveCompare(values[0]), .orderedSame)
        }
    }

    fileprivate func testRequest(forPath path: String, encoding: HTTPRequestData.ParameterEncoding,
                             method: HTTPRequestData.Method, testingClosure: (URLRequest) -> Void) {
        do {
            let request = try self.request(for: path, withEncoding: encoding, method: method)
            XCTAssertEqual(request.httpMethod!, method.rawValue)
            self.assert(headers: request.allHTTPHeaderFields ?? [:])
            testingClosure(request)
        } catch let e {
            XCTFail("\(e)")
        }
    }
}
