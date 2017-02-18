//
//  ConfigurationProtocol.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/26/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

//TODO: Make inner type of `Endpoint`
public protocol ConfigurationProtocol {
    var dataLoadingProcedureFactory: HTTPDataLoadingProcedureFactory { get }
    var dataDeserializationProcedureFactory: DataDeserializationProcedureFactory { get }
    var responseMappingProcedureFactory: ResponseMappingProcedureFactory { get }
}

public struct Configuration: ConfigurationProtocol {

    static var `default`: Configuration!

    public var dataLoadingProcedureFactory: HTTPDataLoadingProcedureFactory
    public var dataDeserializationProcedureFactory: DataDeserializationProcedureFactory
    public var responseMappingProcedureFactory: ResponseMappingProcedureFactory
}
