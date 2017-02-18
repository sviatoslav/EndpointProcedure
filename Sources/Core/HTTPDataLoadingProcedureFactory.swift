//
//  HTTPDataLoadingProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/20/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

public protocol HTTPDataLoadingProcedureFactory {
    func dataLoadingProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData>
}
