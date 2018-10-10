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

struct Main {

    enum Error: Swift.Error {
        case invalidArgumentsCount
        case invalidArgument(String)
        case inputNotSpecified

    }

    init() throws {
        var arguments = CommandLine.arguments
        let isDebug = arguments.count == 1 && arguments.first == ""
        if isDebug {
            arguments = ["/Users/sviatoslavyakymiv/Development/iOSProjects/OpenSource/EndpointProcedure/Example.swift",
                         "-i", "Examples/Basic usage.playground"]
        }
        guard arguments.count > 2 else { throw Error.invalidArgumentsCount }
        arguments.removeFirst()
        let path = isDebug ? "/Users/sviatoslavyakymiv/Development/iOSProjects/OpenSource/EndpointProcedure"
            : FileManager.default.currentDirectoryPath
        let curentFolderURL = URL(fileURLWithPath: path)
        var input: URL? = nil
        var output: URL? = nil

        while !arguments.isEmpty {
            switch arguments.removeFirst() {
            case "--input" where input == nil: fallthrough
            case "-i" where input == nil:
                var file = arguments.removeFirst()
                if file.hasSuffix(".playground") {
                    file += "/Contents.swift"
                }
                input = URL(fileURLWithPath: file, relativeTo: curentFolderURL)
            case "--output" where output == nil: fallthrough
            case "-o" where output == nil:
                output = URL(fileURLWithPath: arguments.removeFirst(), relativeTo: curentFolderURL)
            case let argument:
                throw Error.invalidArgument(argument)
            }
        }

        guard let inputURL = input else {
            throw Error.inputNotSpecified
        }
        let outputURL = output ?? URL(fileURLWithPath: "output.md", relativeTo: curentFolderURL)

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
