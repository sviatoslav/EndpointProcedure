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
let examplesPath = FileManager.default.currentDirectoryPath + "/Examples"
let playgrounds = (try? FileManager.default.contentsOfDirectory(atPath: examplesPath)
    .filter({ $0.hasSuffix(".playground") })) ?? []
playgrounds.forEach {
    let escapedPlaygroundName = [" ", "`"].reduce($0, { return $0.replacingOccurrences(of: $1, with: "\\\($1)") })
    let playgroundSources = "Examples/\(escapedPlaygroundName)/Sources"
    let sourcesSubdirs = ["Core", "Alamofire", "Decoding"]
    let podsSubdirs = ["Alamofire/Source", "ProcedureKit/Sources/ProcedureKit"]
    shell("rm -rf \(playgroundSources)")
    shell("mkdir \(playgroundSources)")
    sourcesSubdirs.forEach {
        shell("cp -a Sources/\($0)/. \(playgroundSources)")
    }
    podsSubdirs.forEach {
        shell("cp -a Pods/\($0)/. \(playgroundSources)")
    }
    shell("rm -rf \(playgroundSources)/DispatchQueue+Alamofire.swift")
    shell("cp -a Examples/Supporting\\ Files/ \(playgroundSources)")

}
