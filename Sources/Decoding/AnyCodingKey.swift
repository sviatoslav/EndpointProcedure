//
//  AnyCodingKey.swift
//  DecodingProcedureFactory
//
//  Created by Sviatoslav Yakymiv on 8/28/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

public struct AnyCodingKey: CodingKey, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    public var stringValue: String
    public var intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }

    public init(stringLiteral value: String) {
        self.init(stringValue: value)!
    }

    public init(integerLiteral value: Int) {
        self.init(intValue: value)!
    }
}
