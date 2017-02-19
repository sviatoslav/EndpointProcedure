//
//  HTTPRequestData.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 12/17/16.
//  Copyright © 2016 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

///Represents values passed to HTTP request
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
    /// HTTP method definitions.
    ///
    /// See https://tools.ietf.org/html/rfc7231#section-4.3
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
    /// Creates `HTTPRequestData` step by step
    public struct Builder {

        ///URL used for creation relative URLs in `static func for(_ path: String) throws -> Builder`
        public static var baseURL: URL!

        private let url: URL
        private var method: Method?
        private var headerFields: HeaderFields?
        private var parameters: Parameters?
        private var parameterEncoding: ParameterEncoding?

        private init(url: URL) {
            self.url = url
        }

        /// Creates `Builder` for relative `path` to `Builder.baseURL`
        /// - throws:
        /// `Error.undefinedBaseURL` if `Builder.baseURL` is `nil`
        /// `Error.unableToCreateURL` if unable to create URL with `path` relative to `Builder.baseURL`
        /// - returns: `Builder` for url with `path` relative to `Builder.baseURL`
        public static func `for`(_ path: String) throws -> Builder {
            guard let baseURL = self.baseURL else {
                throw Error.undefinedBaseURL
            }
            guard let url = URL(string: path, relativeTo: baseURL) else {
                throw Error.unableToCreateURL
            }
            return self.for(url)
        }

        /// Creates `Builder` for `url`
        /// - returns `Builder` for `url`
        public static func `for`(_ url: URL) -> Builder {
            return Builder(url: url)
        }

        private func changing(_ closure: (inout Builder) -> Void) -> Builder {
            var newBuilder = self
            closure(&newBuilder)
            return newBuilder
        }

        /// Assigns HTTP method to `Builder`
        /// - throws: `Error.reassignProperty(name: "method")` if HTTP method was previously assigned.
        /// - returns: New `Builder` with same properties as receiver but with assigned HTTP method
        public func with(method: Method) throws -> Builder {
            guard self.method == nil else { throw Error.reassignProperty(name: "method") }
            return self.changing {
                $0.method = method
            }
        }

        /// Appends header fields to `Builder`
        /// - returns: New `Builder` with same properties as receiver but with appended header fields
        public func appending(headerFields newHeaderFields: HeaderFields) -> Builder {
            return self.changing {
                var headerFields = $0.headerFields ?? [:]
                newHeaderFields.forEach {
                    headerFields[$0.key] = $0.value
                }
                $0.headerFields = headerFields
            }
        }

        /// Appends header field to `Builder`
        /// - returns: New `Builder` with same properties as receiver but with appended header field
        public func appending(headerFieldValue value: HeaderFields.Value, for key: HeaderFields.Key) -> Builder {
            return self.appending(headerFields: [key: value])
        }

        /// Appends parameters to `Builder`
        /// - returns: New `Builder` with same properties as receiver but with appended parameters
        public func appending(parameters: Parameters) -> Builder {
            return self.changing {
                var params = $0.parameters ?? [:]
                parameters.forEach {

                    params[$0.key] = $0.value
                }
                $0.parameters = params
            }
        }

        /// Appends parameter to `Builder`
        /// - returns: New `Builder` with same properties as receiver but with appended parameter
        public func appending(parameterValue value: Parameters.Value, for key: Parameters.Key) -> Builder {
            return appending(parameters: [key: value])
        }

        /// Assigns parameter encoding to `Builder`
        /// - throws: `Error.reassignProperty(name: "parameterEncoding")` if parameter encoding was previously assigned.
        /// - returns: New `Builder` with same properties as receiver but with assigned parameter encoding
        public func with(parameterEncoding: ParameterEncoding) throws -> Builder {
            guard self.parameterEncoding == nil else {
                throw Error.reassignProperty(name: "parameterEncoding")
            }
            return self.changing {
                $0.parameterEncoding = parameterEncoding
            }
        }

        /// Builds `HTTPRequestData` from configured properties
        /// - returns: Created `HTTPRequestData`
        public func build() -> HTTPRequestData {
            return HTTPRequestData(url: self.url, method: self.method ?? .get, headerFields: self.headerFields,
                                   parameters: self.parameters, parameterEncoding: self.parameterEncoding ?? .url)
        }
    }
}

extension HTTPRequestData.Builder {
    /// Errors that `Builder` may throw during building `HTTPRequestData`
    public enum Error: Swift.Error {
        /// Property that can be assigned only once reassigned
        case reassignProperty(name: String)
        /// `Builder.baseURL == nil`
        case undefinedBaseURL
        /// Unable to create `URL` from provided `path` and `Builder.baseURL`
        case unableToCreateURL
    }
}

extension HTTPRequestData {
    /// Defines how `parameters` of `HTTPRequestData` should be encoded
    public enum ParameterEncoding: Equatable {
        /// Depending on HTTP method `parameters` query shoud be appended to URL or set as HTTP body
        case url
        /// JSON representation of `parameters` should be set as HTTP body
        case json
        /// Plist representation of `parameters` should be set as HTTP body
        case plist(option: PlistEncodingOption)
    }
}

extension HTTPRequestData.ParameterEncoding {
    /// Defines formatting of `plist` parameter encoding
    public enum PlistEncodingOption {
        /// Binary formatting for plist encoding
        case binary
        /// XML formatting for plist encoding
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
