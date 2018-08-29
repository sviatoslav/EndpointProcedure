//
//  TestData.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/29/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
#if ALL
@testable import All
#else
@testable import DecodingProcedureFactory
#endif

enum TestData {
    
    typealias Serialization = (Any) throws -> Data
    
    static let notNestedObject = ["b": "a"]
    static let validNestedObject = ["d": ["c": TestData.notNestedObject]]
    static let invalidNestedObject = ["d": TestData.notNestedObject]
    
    static let notNestedArray = [TestData.notNestedObject, TestData.notNestedObject]
    static let validNestedArray = ["d": ["c": TestData.notNestedArray]]
    static let invalidNestedArray = ["d": TestData.notNestedArray]
    
    static let nestedKeys: [CodingKey] = ["d", "c"].compactMap(AnyCodingKey.init(stringValue:))
    
    static let jsonSerialization: Serialization = { try JSONSerialization.data(withJSONObject: $0) }
    static func plistSerialization(withFormat format: PropertyListSerialization.PropertyListFormat) -> Serialization {
        return { try PropertyListSerialization.data(fromPropertyList: $0, format: format, options: 0) }
    }
    
    static func data(for object: Any, using serialization: Serialization) -> Data {
        return (try? serialization(object)) ?? Data()
    }
}

struct TestObject: Decodable {
    let b: String
    
    enum CodingKeys: String, CodingKey {
        case b
    }
}

struct MockDecoder: DataDecoder {

    private enum Error: Swift.Error {
        case error
    }
    
    let didCallDecode: (Decodable.Type, Data, [CodingKey]) -> Void
    
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        self.didCallDecode(type, data, [])
        throw Error.error
    }
    
    func decode<T>(_ type: T.Type, from data: Data, codingPath: [CodingKey]) throws -> T where T : Decodable {
        self.didCallDecode(type, data, codingPath)
        throw Error.error
    }
}
