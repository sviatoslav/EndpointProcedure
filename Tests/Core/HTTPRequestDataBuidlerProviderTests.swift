//
//  HTTPRequestDataBuidlerProviderTests.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 9/30/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import XCTest
@testable import EndpointProcedure

struct MockHTTPRequestDataBuidlerProvider: HTTPRequestDataBuidlerProviding, BaseURLProviding {
    let baseURL: URL
}

class HTTPRequestDataBuidlerProviderTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testBuilderCreationWithTrailingSlash() {
        let provider = MockHTTPRequestDataBuidlerProvider(baseURL: URL(string: "http://base.url/path/")!)
        do {
            let data = try provider.builder(for: "path1").build()
            XCTAssertEqual(data.url.absoluteString, "http://base.url/path/path1")
        } catch {
            XCTFail()
        }
    }

    func testBuilderCreationWithoutTrailingSlash() {
        let provider = MockHTTPRequestDataBuidlerProvider(baseURL: URL(string: "http://base.url/path")!)
        do {
            let data = try provider.builder(for: "path1").build()
            XCTAssertEqual(data.url.absoluteString, "http://base.url/path1")
        } catch {
            XCTFail()
        }
    }

    func testPathWithLeadingSlash() {
        let provider = MockHTTPRequestDataBuidlerProvider(baseURL: URL(string: "http://base.url/path/")!)
        do {
            let data = try provider.builder(for: "/path1").build()
            XCTAssertEqual(data.url.absoluteString, "http://base.url/path1")
        } catch {
            XCTFail()
        }
    }

    func testBuilderFailure() {
        let provider = MockHTTPRequestDataBuidlerProvider(baseURL: URL(string: "http://base.url/path/")!)
        do {
            _ = try provider.builder(for: "/$%^$%^$(*&()*)").build()
            XCTFail()
        } catch HTTPRequestData.Builder.Error.unableToCreateURL {
        } catch {
            XCTFail()
        }
    }
}
