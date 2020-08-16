import ArgumentParser
import Foundation

struct ParseCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "parse")
    
    @Argument(help: "The version to parse")
    var version: SemanticVersion
    
    @Option(help: "The format of the output")
    var outputFormat: OutputFormat = .normal
    
    mutating func run() throws {
        switch outputFormat {
            case .normal:
                print("Major version: \(version.major)")
                print("Minor version: \(version.minor)")
                print("Patch level:   \(version.patch)")
                print("Prerelease identifiers:")
                print("\t\(version.prereleaseIdentifiers.joined(separator: "\n\t"))")
                print("Build metadata identifiers:")
                print("\t\(version.buildMetadataIdentifiers.joined(separator: "\n\t"))")
            case .json:
                print(String(decoding: try JSONSerialization.data(withJSONObject: [
                    "major": version.major,
                    "minor": version.minor,
                    "patch": version.patch,
                    "prereleaseIdentifiers": version.prereleaseIdentifiers,
                    "buildMetadata": version.buildMetadataIdentifiers
                ], options: .prettyPrinted), as: Unicode.UTF8.self))
            case .xml:
                print("Not implemented.")
                throw ExitCode(EX_UNAVAILABLE)
        }
    }
}

enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
    case normal, json, xml
}
