//
//  ConfigurationProtocol.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

//TODO: Make inner type of `EndpointProcedure`
/// `EndpointProcedure` configuration.
///
/// Provides factories for data loading, deserialization and repsonse mapping procedures
///
public protocol ConfigurationProtocol {
    var dataLoadingProcedureFactory: HTTPDataLoadingProcedureFactory { get }
    var dataDeserializationProcedureFactory: DataDeserializationProcedureFactory { get }
    var responseMappingProcedureFactory: ResponseMappingProcedureFactory { get }
}

/// Default implementation of `ConfigurationProtocol`
public struct Configuration: ConfigurationProtocol {

    /// Configuration that is used in `EndpointProcedure` instances by default.
    static var `default`: Configuration!

    public var dataLoadingProcedureFactory: HTTPDataLoadingProcedureFactory
    public var dataDeserializationProcedureFactory: DataDeserializationProcedureFactory
    public var responseMappingProcedureFactory: ResponseMappingProcedureFactory
}
