//
//  MagicalRecordMappingProcedureError.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/18/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

/// Errors that `MagicalRecordMappingProcedure` can return in `output` property.
public enum MagicalRecordMappingProcedureError: Error {
    /// Data format is wrong or magical record model configured incorrectly
    case unableMapResponse
    /// Type is not supported
    case unsupportedType
}

