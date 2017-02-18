//
//  HTTPRequestData.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/17/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

public struct HTTPRequestData {

    public typealias HeaderFields = [String: String]
    public typealias Parameters = [String: Any]

    public let url: URL
    public let method: Method
    public let headerFields: HeaderFields?
    public let parameters: Parameters?
    public let parameterEncoding: ParameterEncoding

    fileprivate init(url: URL, method: Method, headerFields: HeaderFields?, parameters: Parameters?,
                     parameterEncoding: ParameterEncoding) {
        self.url = url
        self.method = method
        self.headerFields = headerFields
        self.parameters = parameters
        self.parameterEncoding = parameterEncoding
    }
}

extension HTTPRequestData {
    public enum Method: String {
        case options = "OPTIONS"
        case get     = "GET"
        case head    = "HEAD"
        case post    = "POST"
        case put     = "PUT"
        case patch   = "PATCH"
        case delete  = "DELETE"
        case trace   = "TRACE"
        case connect = "CONNECT"
    }
}

extension HTTPRequestData {
    public struct Builder {

        public static var baseURL: URL!

        private let url: URL
        private var method: Method?
        private var headerFields: HeaderFields?
        private var parameters: Parameters?
        private var parameterEncoding: ParameterEncoding?

        private init(url: URL) {
            self.url = url
        }

        public static func `for`(_ path: String) throws -> Builder {
            guard let baseURL = self.baseURL else {
                throw Error.undefinedBaseURL
            }
            guard let url = URL(string: path, relativeTo: baseURL) else {
                throw Error.unableToCreateURL
            }
            return self.for(url)
        }

        public static func `for`(_ url: URL) -> Builder {
            return Builder(url: url)
        }

        private func changing(_ closure: (inout Builder) -> Void) -> Builder {
            var newBuilder = self
            closure(&newBuilder)
            return newBuilder
        }

        public func with(method: Method) throws -> Builder {
            guard self.method == nil else { throw Error.reassignProperty(name: "method") }
            return self.changing {
                $0.method = method
            }
        }

        public func appending(headerFields newHeaderFields: HeaderFields) -> Builder {
            return self.changing {
                var headerFields = $0.headerFields ?? [:]
                newHeaderFields.forEach {
                    headerFields[$0.key] = $0.value
                }
                $0.headerFields = headerFields
            }
        }

        public func appending(headerFieldValue value: HeaderFields.Value, for key: HeaderFields.Key) -> Builder {
            return self.appending(headerFields: [key: value])
        }

        public func appending(parameters: Parameters) -> Builder {
            return self.changing {
                var params = $0.parameters ?? [:]
                parameters.forEach {

                    params[$0.key] = $0.value
                }
                $0.parameters = params
            }
        }

        public func appending(parameterValue value: Parameters.Value, for key: Parameters.Key) -> Builder {
            return appending(parameters: [key: value])
        }

        public func with(parameterEncoding: ParameterEncoding) throws -> Builder {
            guard self.parameterEncoding == nil else {
                throw Error.reassignProperty(name: "parameterEncoding")
            }
            return self.changing {
                $0.parameterEncoding = parameterEncoding
            }
        }

        public func build() -> HTTPRequestData {
            return HTTPRequestData(url: self.url, method: self.method ?? .get, headerFields: self.headerFields,
                                   parameters: self.parameters, parameterEncoding: self.parameterEncoding ?? .url)
        }
    }
}

extension HTTPRequestData.Builder {
    public enum Error: Swift.Error {
        case reassignProperty(name: String)
        case undefinedBaseURL
        case unableToCreateURL
    }
}

extension HTTPRequestData {
    public enum ParameterEncoding: Equatable {
        case url
        case json
        case plist(option: PlistEncodingOption)
    }
}

extension HTTPRequestData.ParameterEncoding {
    public enum PlistEncodingOption {
        case binary
        case xml
    }
}

public func ==(lhs: HTTPRequestData.ParameterEncoding, rhs: HTTPRequestData.ParameterEncoding) -> Bool {
    switch (lhs, rhs) {
    case (.url, .url): return true
    case (.json, .json): return true
    case let (.plist(option: lhsOption), .plist(option: rhsOption)) where lhsOption == rhsOption: return true
    default: return false
    }
}
