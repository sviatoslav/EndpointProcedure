//
//  HTTPURLResponseProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit

public protocol HTTPURLResponseProcedure: ProcedureProtocol {
    var urlResponse: Pending<HTTPURLResponse> { get }
}
