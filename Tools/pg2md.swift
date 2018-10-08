import Foundation

enum LiteralType {
    case markdown(String)
    case code(String)
}

protocol StringGenerating {
    static func string(from literals: [LiteralType]) -> String
}

struct MarkdownStringGenerator: StringGenerating {
    static func string(from literals: [LiteralType]) -> String {
        return literals.map({
            switch $0 {
            case .markdown(let markdown):
                return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
            case .code(let code):
                return ["```swift", code.trimmingCharacters(in: .whitespacesAndNewlines), "```"].joined(separator: "\n")
            }
        }).joined(separator: "\n\n")
    }
}

protocol ComandLineOption {

}

struct Main {

    enum Error: Swift.Error {
        case invalidArgumentsCount
        case invalidPath(String)
        case invalidPathExtention
        case invalidArgument(String)
        case inputNotSpecified

    }

    static func url(for path: String, relativeTo baseURL: URL) throws -> URL {
        guard let url = URL(string: path, relativeTo: baseURL), url.isFileURL else {
            throw Error.invalidPath(path)
        }
        return url
    }

    static func url(for path: String, relativeTo baseURL: URL, validFileExtensions: [String]) throws -> URL {
        let url = try self.url(for: path, relativeTo: baseURL)
        guard validFileExtensions.contains(url.pathExtension) == true else {
            throw Error.invalidPathExtention
        }
        return url
    }

    static func outputURL(forPath path: String, relativeTo baseURL: URL) throws -> URL {
        return try self.url(for: path, relativeTo: baseURL, validFileExtensions: ["md"])
    }

    static func defaultOutputURL(forBaseURL url: URL) throws -> URL {
        return try self.outputURL(forPath: "output.md", relativeTo: url)
    }

    static func inputURL(forPath path: String, relativeTo baseURL: URL) throws -> URL {
        var path = path
        if path.hasSuffix(".playground") {
            path = path + "/Contents.swift"
        }
        return try self.url(for: path, relativeTo: baseURL, validFileExtensions: ["swift"])
    }

    init() throws {
        var arguments = CommandLine.arguments
        let isDebug = arguments.count == 1 && arguments.first == ""
        if isDebug {
            arguments = ["/Users/sviatoslavyakymiv/Development/iOSProjects/OpenSource/EndpointProcedure/Example.swift",
                         "-i", "Example.playground"]
        }
        guard arguments.count > 2 else { throw Error.invalidArgumentsCount }
        arguments.removeFirst()
        let path = isDebug ? "/Users/sviatoslavyakymiv/Development/iOSProjects/OpenSource/EndpointProcedure"
            : FileManager.default.currentDirectoryPath
        let curentFolderURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        var input: URL? = nil
        var output: URL? = nil

        while !arguments.isEmpty {
            switch arguments.removeFirst() {
            case "--input" where input == nil: fallthrough
            case "-i" where input == nil:
                input = try Main.inputURL(forPath: arguments.removeFirst(), relativeTo: curentFolderURL)
            case "--output" where output == nil: fallthrough
            case "-o" where output == nil:
                output = try Main.outputURL(forPath: arguments.removeFirst(), relativeTo: curentFolderURL)
            case let argument:
                throw Error.invalidArgument(argument)
            }
        }

        guard let inputURL = input else {
            throw Error.inputNotSpecified
        }
        let outputURL = try output ?? Main.defaultOutputURL(forBaseURL: curentFolderURL)

        let data = try Data(contentsOf: inputURL)
        var content = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)

        var result: [LiteralType] = []
        while !content.isEmpty {
            guard let nextMarkdownStartGrapheme = content.range(of: "/*:") else {
                result.append(.code(content))
                break
            }
            let code = content[..<nextMarkdownStartGrapheme.lowerBound]
            if !code.isEmpty {
                result.append(.code(String(code)))
            }
            content = String(content[nextMarkdownStartGrapheme.upperBound...])
            guard let nextMarkdownEndGrapheme = content.range(of: "*/") else {
                result.append(.markdown(content))
                break
            }
            let markdown = String(content[..<nextMarkdownEndGrapheme.lowerBound])
            if !markdown.isEmpty {
                result.append(.markdown(markdown))
            }
            content = String(content[nextMarkdownEndGrapheme.upperBound...])
        }
        try MarkdownStringGenerator.string(from: result).data(using: .utf8)?.write(to: outputURL)
    }
}

do {
    let _ = try Main()
} catch {
    print(error)
    exit(1)
}
