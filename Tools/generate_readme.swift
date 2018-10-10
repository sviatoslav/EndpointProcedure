import Foundation

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/swift"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

let pjinjectPath = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
    .appendingPathComponent("pginject.swift")
shell(pjinjectPath.path, "-i", "README.template.md", "-o", "README.md")
