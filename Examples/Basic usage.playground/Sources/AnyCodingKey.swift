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
        self.init(stringLiteral: stringValue)
    }
    
    public init?(intValue: Int) {
        self.init(integerLiteral: intValue)
    }

    public init(stringLiteral value: String) {
        self.stringValue = value
        self.intValue = nil
    }

    public init(integerLiteral value: Int) {
        self.stringValue = String(value)
        self.intValue = value
    }
}
