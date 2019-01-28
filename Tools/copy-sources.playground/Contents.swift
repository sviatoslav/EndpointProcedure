import Cocoa

@discardableResult
func shell(_ command: String) -> Int32 {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", command]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func packageDirectoryPath(withPrefix prefix: String) -> String? {
    let checkoutsPath = FileManager.default.currentDirectoryPath + "/.build/checkouts"
    return (try? FileManager.default.contentsOfDirectory(atPath: checkoutsPath))?
        .first(where: { $0.hasPrefix(prefix) }).map({ [checkoutsPath, $0].joined(separator: "/") })
}

var alamofireDirectoryPath: String? {
    return packageDirectoryPath(withPrefix: "Alamofire.git")?.appending("/Source")
}

var procedureKitDirectoryPath: String? {
    return packageDirectoryPath(withPrefix: "ProcedureKit.git")?.appending("/Sources/ProcedureKit")
}

let examplesPath = FileManager.default.currentDirectoryPath + "/Examples"
let playgrounds = (try? FileManager.default.contentsOfDirectory(atPath: examplesPath)
    .filter({ $0.hasSuffix(".playground") })) ?? []
playgrounds.forEach {
    let playgroundSources = "Examples/\($0.replacingOccurrences(of: " ", with: "\\ "))/Sources"
    let sourcesSubdirs = ["Core", "Alamofire", "Decoding"]
    shell("rm -rf \(playgroundSources)")
    shell("mkdir \(playgroundSources)")
    sourcesSubdirs.forEach {
        shell("cp -a Sources/\($0)/. \(playgroundSources)")
    }
    [alamofireDirectoryPath, procedureKitDirectoryPath].compactMap({ $0 }).forEach {
        shell("cp -a \($0)/. \(playgroundSources)")
    }
    shell("rm -rf \(playgroundSources)/DispatchQueue+Alamofire.swift")
    shell("cp -a Examples/Supporting\\ Files/ \(playgroundSources)")
}
