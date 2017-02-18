//
//  LocalDataLoadingProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/17/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
import ProcedureKit

public class ContentsOfURLLoadingProcedure: Procedure, OutputProcedure {

    public var output: Pending<ProcedureResult<Data>> = .pending

    private let url: URL

    public init(url: URL) {
        self.url = url
        super.init()
    }

    override public func execute() {
        do {
            let data = try Data(contentsOf: self.url)
            finish(withResult: .success(data))
        }
        catch let e {
            finish(withResult: .failure(e))
        }
    }
}
