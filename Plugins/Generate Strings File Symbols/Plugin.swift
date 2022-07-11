import Foundation
import PackagePlugin

extension Path {
    /// Returns the deepest path component matching the given predicate.
    func deepestComponent(matching predicate: (String) -> Bool) -> String? {
        if predicate(lastComponent) {
            return lastComponent
        } else {
            let parent = self.removingLastComponent()
            if parent == self { return nil }
            return parent.deepestComponent(matching: predicate)
        }
    }
}

@main struct GenerateSymbols: BuildToolPlugin {

    struct StringsFileMetadata {
        let tableName: String
        let lprojName: String
        let keyCount: Int
        let path: Path
    }

    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        return try stringsFilesToProcess(in: Array(target.sourceFiles(withSuffix: "strings"))).map({ stringsFile in
            let outputFile = context.pluginWorkDirectory.appending(subpath: "\(stringsFile.tableName).swift")
            let name = "Generating symbols for \(stringsFile.keyCount) keys in \(stringsFile.path.lastComponent) from \(stringsFile.lprojName)"

            return .buildCommand(displayName: name,
                                 executable: try context.tool(named: "generate-symbols-tool").path,
                                 arguments: [stringsFile.path.string, outputFile.string],
                                 inputFiles: [stringsFile.path],
                                 outputFiles: [outputFile])
        })
    }

    func stringsFilesToProcess(in files: [File]) -> [StringsFileMetadata] {
        // Strings files are a little unusual — they effectively redefine the same thing over and over again, so
        // we can't just output a Swift struct for every strings file we encounter. Unfortunately, it doesn't appear
        // that we can introspect the project to figure out the development language, so this plugin instead decides
        // to generate symbols from the file we find that has the most keys for a particular table name.
        let tablesToGenerate: [String: StringsFileMetadata] = files.reduce(into: [:], { partialResult, stringsFile in
            let inputPath = stringsFile.path
            let tableName = stringsFile.path.stem
            let keyCount = numberOfKeys(in: inputPath.string)
            let lprojName = inputPath.deepestComponent(matching: { $0.hasSuffix(".lproj") }) ?? "unknown"
            let metadata = StringsFileMetadata(tableName: tableName, lprojName: lprojName, keyCount: keyCount, path: stringsFile.path)

            if let existing = partialResult[tableName] {
                if metadata.keyCount > existing.keyCount { partialResult[tableName] = metadata }
            } else {
                partialResult[tableName] = metadata
            }
        })

        return Array(tablesToGenerate.values)
    }

    func numberOfKeys(in stringsFilePath: String) -> Int {
        do {
            let stringsData = try Data(contentsOf: URL(fileURLWithPath: stringsFilePath))
            let plistObject = try PropertyListSerialization.propertyList(from: stringsData, format: nil)
            guard let stringsDictionary = plistObject as? [String: String] else {
                print("Failed to parse strings file — is it valid?")
                return 0
            }
            return stringsDictionary.keys.count
        } catch {
            print("Failed to parse strings file — is it valid?")
            return 0
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension GenerateSymbols: XcodeBuildToolPlugin {

    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        return try stringsFilesToProcess(in: target.inputFiles.filter({ $0.path.extension == "strings" })).map({ stringsFile in
            let outputFile = context.pluginWorkDirectory.appending(subpath: "\(stringsFile.tableName).swift")
            let name = "Generating symbols for \(stringsFile.keyCount) keys in \(stringsFile.path.lastComponent) from \(stringsFile.lprojName)"

            return .buildCommand(displayName: name,
                                 executable: try context.tool(named: "generate-symbols-tool").path,
                                 arguments: [stringsFile.path.string, outputFile.string],
                                 inputFiles: [stringsFile.path],
                                 outputFiles: [outputFile])
        })
    }
}
#endif