//
//  HTTPRequestDataBuilderTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/18/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
@testable import EndpointProcedure

class HTTPRequestDataTests: XCTestCase {

    private let url = URL(string: "https://my.custom.api")!
    private let allHTTPMethods: [HTTPRequestData.Method] =  [.options, .get, .head, .post, .put, .patch, .delete,
                                                             .trace, .connect]
    private let allParameterEncodings: [HTTPRequestData.ParameterEncoding] = [.url, .json, .plist(option: .binary),
                                                                              .plist(option: .xml)]

    override func setUp() {
        super.setUp()
        HTTPRequestData.Builder.baseURL = URL(string: "https://my.api/v1/")!
    }

    func testParameterEncodingEquatableConformance() {
        let encodings = allParameterEncodings
        for i in 0..<encodings.count {
            for j in 0..<encodings.count {
                if i == j {
                    XCTAssertEqual(encodings[i], encodings[j])
                } else {
                    XCTAssertNotEqual(encodings[i], encodings[j])
                }
            }
        }
    }

    func testDefaultValues() {
        let data = HTTPRequestData.Builder.for(self.url).build()
        self.assertEqual(data: data, url: self.url)
    }

    func testHTTPMethodPositiveCase() {
        do {
            try self.allHTTPMethods.forEach {
                let data = try HTTPRequestData.Builder.for(url).with(method: $0).build()
                self.assertEqual(data: data, url: self.url, method: $0)
            }
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func testHTTPMethodReassigning() {
        allHTTPMethods.forEach { method in
            allHTTPMethods.forEach {
                do {
                    let _ = try HTTPRequestData.Builder.for(url).with(method: method).with(method: $0).build()
                    XCTFail("Error not thrown")
                } catch HTTPRequestData.Builder.Error.reassignProperty(name: "method") {
                } catch let e {
                    XCTFail("\(e)")
                }
            }
        }
    }

    func testParameterEncodingPositiveCase() {
        do {
            try self.allParameterEncodings.forEach {
                let data = try HTTPRequestData.Builder.for(url).with(parameterEncoding: $0).build()
                self.assertEqual(data: data, url: self.url, parameterEncoding: $0)
            }
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func testParameterEncodingReassigning() {
        allParameterEncodings.forEach { parameterEncoding in
            allParameterEncodings.forEach {
                do {
                    let _ = try HTTPRequestData.Builder.for(url).with(parameterEncoding: parameterEncoding)
                        .with(parameterEncoding: $0).build()
                    XCTFail("Error not thrown")
                } catch HTTPRequestData.Builder.Error.reassignProperty(name: "parameterEncoding") {
                } catch let e {
                    XCTFail("\(e)")
                }
            }
        }
    }

    func testParameters() {
        var dict: HTTPRequestData.Parameters = ["bool": true, "string": "str", "int": 1, "double": 3.2, "date": Date()]
        self.assertEqual(data: HTTPRequestData.Builder.for(self.url).appending(parameters: dict).build(),
                         url: self.url, parameters: dict)

        var builder = HTTPRequestData.Builder.for(self.url).appending(parameters: dict).appending(parameters: dict)
        self.assertEqual(data: builder.build(), url: self.url, parameters: dict)

        builder = HTTPRequestData.Builder.for(self.url).appending(parameters: dict)
            .appending(parameterValue: 13, for: "key")
        dict["key"] = 13
        self.assertEqual(data: builder.build(), url: self.url, parameters: dict)
    }

    func testHeaderFields() {
        var fields = ["1": "1", "2": "2", "3": "3"]
        self.assertEqual(data: HTTPRequestData.Builder.for(self.url).appending(headerFields: fields)
            .appending(headerFields: fields).build(), url: self.url, headerFields: fields)
        self.assertEqual(data: HTTPRequestData.Builder.for(self.url).appending(headerFields: fields).build(), url: self.url, headerFields: fields)
        let builder = HTTPRequestData.Builder.for(self.url).appending(headerFields: fields)
            .appending(headerFieldValue: "4", for: "4")
        fields["4"] = "4"
        self.assertEqual(data: builder.build(), url: self.url, headerFields: fields)
    }

    private func assertEqual(data: HTTPRequestData, url: URL, method: HTTPRequestData.Method = .get,
                             headerFields: HTTPRequestData.HeaderFields? = nil,
                             parameters: HTTPRequestData.Parameters? = nil,
                             parameterEncoding: HTTPRequestData.ParameterEncoding = .url) {
        XCTAssertEqual(data.url, url, "Incorrect url")
        XCTAssertEqual(data.method, method, "Incorrect method")
        XCTAssertEqual(data.headerFields.map({NSDictionary.init(dictionary:$0)}),
                       headerFields.map({NSDictionary.init(dictionary:$0)}), "Incorrect header fields")
        XCTAssertEqual(data.parameters.map({NSDictionary.init(dictionary:$0)}),
                       parameters.map({NSDictionary.init(dictionary:$0)}), "Incorrect parameters")
        XCTAssertEqual(data.parameterEncoding, parameterEncoding, "Incorrect url")
    }

    func testURLForPathWithLeadingSlash() {
        XCTAssertEqual("https://my.api/users", try HTTPRequestData.Builder.for("/users").build().url.absoluteString)
    }

    func testURLForPathWithoutLeadingSlash() {
        XCTAssertEqual("https://my.api/v1/users", try HTTPRequestData.Builder.for("users").build().url.absoluteString)
    }

    func testUnableToCreateURL() {
        let expectation = self.expectation(description: "Crash expectation")
        do {
            _ = try HTTPRequestData.Builder.for("").build().url.absoluteString
        } catch HTTPRequestData.Builder.Error.unableToCreateURL {
            expectation.fulfill()
        } catch { }
        self.waitForExpectations(timeout: 0, handler: nil)
    }

    func testUndefinedBaseURL() {
        HTTPRequestData.Builder.baseURL = nil
        let expectation = self.expectation(description: "Crash expectation")
        do {
            _ = try HTTPRequestData.Builder.for("").build().url.absoluteString
        } catch HTTPRequestData.Builder.Error.undefinedBaseURL {
            expectation.fulfill()
        } catch { }
        self.waitForExpectations(timeout: 0, handler: nil)
    }
}

