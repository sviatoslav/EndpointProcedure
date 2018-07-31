//
//  AlamofireProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/18/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import ProcedureKit
import Alamofire
import EndpointProcedure

/// Errors that `AlamofireProcedure` can return in `output` property.
public enum AlamofireProcedureError: Swift.Error {
    /// Request to server did not fail, but response data is `nil`
    case invalidDataRequest
}

/// Procedure that wrapps `Alamofire.DataRequest`
class AlamofireProcedure: Procedure, OutputProcedure {

    var output: Pending<ProcedureResult<HTTPResponseData>> = .pending

    let request: DataRequest

    /// Creates `AlamofireProcedure`.
    ///
    /// - parameter request: `Alamofire.DataRequest` for data loading.
    init(request: DataRequest) {
        self.request = request
        super.init()
    }

    override func execute() {
        self.request.response { [weak self] in
            if let error = $0.error {
                self?.finish(withResult: .failure(error))
            } else {
                if let data = $0.data {
                    let result = HTTPResponseData(urlResponse: $0.response, data: data)
                    self?.finish(withResult: .success(result))
                } else {
                    self?.finish(withResult: .failure(AlamofireProcedureError.invalidDataRequest))
                }
            }
        }
    }
}
