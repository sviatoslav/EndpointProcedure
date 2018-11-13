//
//  AnyCodingKey.swift
//  DecodingProcedureFactory
//
//  Created by Sviatoslav Yakymiv on 8/28/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

/// Type that simplifies creation of coding keys from string or integer literal.
public struct AnyCodingKey: CodingKey, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    public var stringValue: String
    public var intValue: Int?

    /// Creates a new instance from the given string.
    ///
    /// - parameter stringValue: The string value of the desired key.
    public init?(stringValue: String) {
        self.init(stringLiteral: stringValue)
    }

    /// Creates a new instance from the specified integer.
    ///
    /// - parameter intValue: The integer value of the desired key.
    public init?(intValue: Int) {
        self.init(integerLiteral: intValue)
    }

    /// Creates a new instance from the given string.
    ///
    /// - parameter stringValue: The string value of the desired key.
    public init(stringLiteral value: String) {
        self.stringValue = value
        self.intValue = nil
    }

    /// Creates a new instance from the specified integer.
    ///
    /// - parameter intValue: The integer value of the desired key.
    public init(integerLiteral value: Int) {
        self.stringValue = String(value)
        self.intValue = value
    }
}
