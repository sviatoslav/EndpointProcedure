//
//  DataDecoder.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 8/29/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

public protocol DataDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
    func decode<T>(_ type: T.Type, from data: Data, codingPath: [CodingKey]) throws -> T where T : Decodable
}

extension DataDecoder {
    fileprivate func object(at codingPath: [CodingKey], of object: Any) throws -> Any {
        var innerObject = object
        var iterator = codingPath.makeIterator()
        var currentPath: [CodingKey] = []
        while let currentKey = iterator.next() {
            currentPath.append(currentKey)
            guard let newInnerObject = (innerObject as? [AnyHashable: Any])?[currentKey.stringValue] else {
                throw DecodingError.keyNotFound(currentKey, DecodingError.Context(codingPath: currentPath,
                                                                                  debugDescription: "Key not found"))
            }
            innerObject = newInnerObject
        }
        return innerObject
    }
    
    func decode<T>(_ type: T.Type, from data: Data, codingPath: [CodingKey],
                               formatName: String,
                               deserialization: (Data) throws -> Any,
                               serialization: (Any) throws -> Data) throws -> T where T : Decodable {
        guard !codingPath.isEmpty else {
            return try self.decode(type, from: data)
        }
        let result: T
        do {
            let object = try deserialization(data)
            let innerObject = try self.object(at: codingPath, of: object)
            let innerData = try serialization(innerObject)
            result = try self.decode(type, from: innerData)
        } catch let error where !(error is DecodingError) {
            let description = "The given data was not valid \(formatName)."
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: description,
                                                                    underlyingError: error))
        }
        return result
    }
}

extension DataDecoder where Self: JSONDecoder {
    public func decode<T>(_ type: T.Type, from data: Data, codingPath: [CodingKey]) throws -> T where T : Decodable {
        return try self.decode(type, from: data, codingPath: codingPath, formatName: "JSON",
                               deserialization: { return try JSONSerialization.jsonObject(with: $0, options: []) },
                               serialization: { return try JSONSerialization.data(withJSONObject: $0) })
    }
}

extension DataDecoder where Self: PropertyListDecoder {
    public func decode<T>(_ type: T.Type, from data: Data, codingPath: [CodingKey]) throws -> T where T : Decodable {
        var plistFormat = PropertyListSerialization.PropertyListFormat.binary
        let deserialization: (Data) throws -> Any = {
            return try PropertyListSerialization.propertyList(from: $0, format: &plistFormat)
        }
        let serialization: (Any) throws -> Data = {
            return try PropertyListSerialization.data(fromPropertyList: $0, format: plistFormat, options: 0)
        }
        return try self.decode(type, from: data, codingPath: codingPath, formatName: "property list",
                               deserialization: deserialization, serialization: serialization)
    }
}

extension JSONDecoder: DataDecoder {}
extension PropertyListDecoder: DataDecoder {}
