//
//  HTTPDataLoadingProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/20/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

/// A type that can create HTTP data loading procedure
public protocol HTTPDataLoadingProcedureFactory {
    /// Creates HTTP data loading procedure, throws error if unable to create procedure.
    ///
    /// - parameter data: `HTTPRequestData` used in procedure creation
    func dataLoadingProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData>
}
