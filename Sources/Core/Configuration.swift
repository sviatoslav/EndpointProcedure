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
    /// Factory that creates loading procedure with `HTTPRequestData` for `EndpointProcedure`
    var dataLoadingProcedureFactory: HTTPDataLoadingProcedureFactory { get }
    /// Factory that creates deserialization procdure for `EndpointProcedure`
    var dataDeserializationProcedureFactory: DataDeserializationProcedureFactory { get }
    /// Factory that creates mapping procedure for type passed as parameter
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
