//
//  AlamofireProcedureFactory.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/20/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Alamofire
import ProcedureKit
import EndpointProcedure

/// `HTTPDataLoadingProcedureFactory` that creates `AlamofireProcedure`s
public struct AlamofireProcedureFactory: HTTPDataLoadingProcedureFactory {

    private let sessionManager: SessionManager

    /// Creates `AlamofireProcedureFactory` with `sessionManager`
    ///
    /// - parameter sessionManager: `Alamifire.SessionManager` that is used in alamofire procedures creation.
    /// Default value: `SessionManager.default`
    public init(sessionManager: SessionManager = .default) {
        self.sessionManager = sessionManager
    }

    /// Creates `AlamofireProcedure` with `sessionManager` provided in initializer.
    ///
    /// - throws: `AlamofireProcedureFactory` does not throw error from `dataLoadingProcedure(with:)`
    /// - parameter data: `HTTPRequestData` used in procedure creation
    public func dataLoadingProcedure(with data: HTTPRequestData) throws -> AnyOutputProcedure<HTTPResponseData> {
        let method = AlamofireProcedureFactory.alamofireHTTPMethod(for: data.method)
        let encoding = AlamofireProcedureFactory.parameterEncoding(for: data.parameterEncoding)
        let procedure =  AlamofireProcedure(request: self.sessionManager.request(data.url, method: method,
                                                                                 parameters: data.parameters,
                                                                                 encoding: encoding,
                                                                                 headers: data.headerFields))
        return AnyOutputProcedure(procedure)
    }

    private static func parameterEncoding(for endcoding: HTTPRequestData.ParameterEncoding) -> ParameterEncoding {
        switch endcoding {
        case .url: return URLEncoding()
        case .json: return JSONEncoding()
        case .plist(option: .binary): return PropertyListEncoding(format: .binary, options: 0)
        case .plist(option: .xml): return PropertyListEncoding(format: .xml, options: 0)
        }
    }

    private static func alamofireHTTPMethod(for method: HTTPRequestData.Method) -> HTTPMethod {
        return HTTPMethod(rawValue: method.rawValue)!
    }
}
