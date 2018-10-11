//
//  LocalDataLoadingProcedure.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/17/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation
#if canImport(ProcedureKit)
import ProcedureKit
#endif

/// Wrapps `Data(contensOf:)`. Sets result `Data` as `output`.
///
/// If `Data(contensOf:)` throws error sets it as `output`
public class ContentsOfURLLoadingProcedure: Procedure, OutputProcedure {

    /// Result of `Data(contensOf:)` initializer
    public var output: Pending<ProcedureResult<Data>> = .pending

    private let url: URL

    /// Creates `ContentsOfURLLoadingProcedure` with given URL
    ///
    /// - parameter url: URL that should be used in `Data(contensOf:)`
    public init(url: URL) {
        self.url = url
        super.init()
    }

    /// Executes loading content from `url`
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
