//
//  HTTPURLResponseProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/9/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif

/// A procedure type that containts `HTTPURLResponse`
public protocol HTTPURLResponseProcedure: ProcedureProtocol {
    /// `HTTPURLResponse` recieved from procedure
    var urlResponse: Pending<HTTPURLResponse> { get }
}
