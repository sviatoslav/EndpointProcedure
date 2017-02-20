//
//  DataDeserializationProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 1/4/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

/// A type that can create data deserialization procedure
public protocol DataDeserializationProcedureFactory {
    /// Creates data deserilization procedure
    func dataDeserializationProcedure() -> AnyProcedure<Data, Any>
}
