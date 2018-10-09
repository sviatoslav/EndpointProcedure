import Foundation

enum Error: Swift.Error {
    case invalidPath
    case invalidOption
}

var arguments = CommandLine.arguments
let isDebug = arguments.count == 1 && arguments.first == ""
if isDebug {
    arguments = ["/Users/sviatoslavyakymiv/Development/iOSProjects/OpenSource/EndpointProcedure/Tools/some.swift",
                 "-i", "README.template.md"]
}
let currentDirectoryPath = isDebug ? "/Users/sviatoslavyakymiv/Development/iOSProjects/OpenSource/EndpointProcedure/"
    : FileManager.default.currentDirectoryPath
let scriptPath = arguments.removeFirst()
let currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)

var input: URL? = nil
var output: URL? = nil

func fileURL(forPath path: String, relativeTo baseURL: URL) throws -> URL {
    guard let url = URL(string: path, relativeTo: baseURL) else { throw Error.invalidPath }
    return url
}

while !arguments.isEmpty {
    switch arguments.removeFirst() {
    case "-i" where input == nil: fallthrough
    case "--input" where input == nil:
        do {
            input = try fileURL(forPath: arguments.removeFirst(), relativeTo: currentDirectoryURL)
        } catch Error.invalidPath {
            print("Invalid input path")
            exit(-1)
        } catch {
            exit(-1)
        }
    case "-o" where output == nil: fallthrough
    case "--output" where output == nil:
        do {
            output = try fileURL(forPath: arguments.removeFirst(), relativeTo: currentDirectoryURL)
        } catch Error.invalidPath {
            print("Invalid output path")
            exit(-1)
        } catch {
            exit(-1)
        }
    case let option: print("Invalid option \(option)"); exit(-1)
    }
}

guard let inputURL = input else {
    print("Input not defined")
    exit(-1)
}
let outputURL = try output ?? fileURL(forPath: "output.md", relativeTo: currentDirectoryURL)
var content: String = ""
do {
    content = try String(contentsOf: inputURL)
} catch {
    print("Can't read input file")
    exit(-1)
}
let openningSpan = "<span( | .* |[^>])class=('|\")playground('|\")(>| .*?>)"
let title = "\\[.*]"
let link = "(.*)"
let closingSpan = "<\\/span>"

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/swift"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

let pg2mdPath = URL(fileURLWithPath: scriptPath).deletingLastPathComponent().appendingPathComponent("pg2md.swift").path

while let range = content.range(of: "\(openningSpan)\(title)\(link)\(closingSpan)", options: .regularExpression) {
    let matchingString = String(content[range])
    let playgroundTitle = matchingString
        .replacingOccurrences(of: "\(openningSpan)\\[", with: "", options: .regularExpression)
        .replacingOccurrences(of: "]\(link)\(closingSpan)", with: "", options: .regularExpression)
    let playgroundLink = matchingString
        .replacingOccurrences(of: "\(openningSpan)\(title)", with: "", options: .regularExpression)
        .replacingOccurrences(of: "\(closingSpan)", with: "", options: .regularExpression)
        .dropFirst()
        .dropLast()
    let playgroundPath = try fileURL(forPath: String(playgroundLink), relativeTo: inputURL).path
    let markdownPath = playgroundPath + ".md"
    shell(pg2mdPath, "-i", playgroundPath, "-o", markdownPath)
    let markdownURL = URL(fileURLWithPath: markdownPath)
    let markdownString = try String(contentsOf: markdownURL)
    try FileManager.default.removeItem(at: markdownURL)
    let dropDownString = "<details><summary>\(playgroundTitle)</summary>\n\n\(markdownString)\n</details>"
    content = content.replacingOccurrences(of: matchingString, with: dropDownString, options: [], range: nil)
}

try content.write(to: outputURL, atomically: true, encoding: .utf8)

