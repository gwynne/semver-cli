import ArgumentParser

struct CompareCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "compare")
    
    @Argument(help: ArgumentHelp("The first semantic version number to compare", valueName: "first"))
    var leftVersion: SemanticVersion
    
    @Argument(help: ArgumentHelp("The logical operator to apply to the version numbers", discussion: """
        Several logical operators are recognized. It is usually recommended to
        use the alphabetic names (such as "eq") instead of the symbolic names
        to avoid problems caused by the shell accidentally treating them as
        metacharacters.
        
          ==, eq, equal     True if the versions have equal precedence
          !=, ne, unequal   True if the versions do not have equal precedence
          <, lt, older      True if the second version has higher precedence
          <=, le, notNewer  True if the second version's precedence isn't lower
          >, gt, newer      True if the first version has higher precedence
          >=, ge, notOlder  True if the first version's precedence isn't higher
          
        """, valueName: "operation")
    )
    var operation: ComparisonOperation
    
    @Argument(help: ArgumentHelp("The second semantic version number to compare", valueName: "second"))
    var rightVersion: SemanticVersion
    
    @Flag
    var outputBehavior: CompareOutputBehavior = .normal
    
    @Flag(
        name: [.customShort("r"), .customLong("reverse"), .customLong("invert")],
        help: .init(abstract: "Invert the comparison result.", discussion: """
            This is equivalent to switching the order of the arguments in most cases.
            If the two versions provided are equal, the result will not change.
            """)
    )
    var invertResult: Bool = false
    
    @Flag
    var mode: CompareOperatorMode = .precedence
    
    mutating func run() throws {
        let compareLeftVersion: SemanticVersion
        let compareRightVersion: SemanticVersion
        
        switch (mode, operation) {
            case (.traditional, _):
                compareLeftVersion = .init(
                    leftVersion.major, leftVersion.major, leftVersion.patch,
                    prereleaseIdentifiers: [], buildMetadataIdentifiers: []
                )
                compareRightVersion = .init(
                    rightVersion.major, rightVersion.major, rightVersion.patch,
                    prereleaseIdentifiers: [], buildMetadataIdentifiers: []
                )
            case (.strictEquality, .equality), (.strictEquality, .inequality), (.strictComparison, _):
                compareLeftVersion = .init(
                    leftVersion.major, leftVersion.major, leftVersion.patch,
                    prereleaseIdentifiers: leftVersion.prereleaseIdentifiers,
                    buildMetadataIdentifiers: leftVersion.buildMetadataIdentifiers
                )
                compareRightVersion = .init(
                    rightVersion.major, rightVersion.major, rightVersion.patch,
                    prereleaseIdentifiers: rightVersion.prereleaseIdentifiers,
                    buildMetadataIdentifiers: rightVersion.buildMetadataIdentifiers
                )
            case (.precedence, _), (.strictEquality, _):
                compareLeftVersion = .init(
                    leftVersion.major, leftVersion.major, leftVersion.patch,
                    prereleaseIdentifiers: leftVersion.prereleaseIdentifiers, buildMetadataIdentifiers: []
                )
                compareRightVersion = .init(
                    rightVersion.major, rightVersion.major, rightVersion.patch,
                    prereleaseIdentifiers: rightVersion.prereleaseIdentifiers, buildMetadataIdentifiers: []
                )
        }

        var result: Bool
        
        switch operation {
            // Provided `Equatable` conformance is strict
            case .equality: result = (compareLeftVersion == compareRightVersion)
            case .inequality: result = (compareLeftVersion != compareRightVersion)
            // Provided `Comparable` conformance uses "precedence" always, use the strict version we define
            case .ascending: result = (compareLeftVersion ⍃ compareRightVersion)
            case .maximal: result = !(compareRightVersion ⍃ compareLeftVersion)
            case .descending: result = (compareRightVersion ⍃ compareLeftVersion)
            case .minimal: result = !(compareLeftVersion ⍃ compareRightVersion)
        }
        if invertResult { result.toggle() }

        switch outputBehavior {
            case .normal:
                print("\(leftVersion) \(result ? "is" : "is not") \(operation.normalDescription) \(rightVersion)")
            case .silent:
                break
            case .verbose:
                print("\(leftVersion) was compared as if it were \"\(compareLeftVersion)\".")
                print("\(rightVersion) was compared as if it were \"\(compareRightVersion)\"")
                print("The comparsion operation was \"\(operation.verboseDescription)?\"")
                print("The result was: \(result ? "yes" : "no").")
            case .debug:
                print("Parsed components of left version:")
                print("\tMajor: \(leftVersion.major)")
                print("\tMinor: \(leftVersion.minor)")
                print("\tPatch: \(leftVersion.patch)")
                print("\tPrerelease identifiers: [\(leftVersion.prereleaseIdentifiers.joined(separator: ", "))]")
                print("\tBuild metadata identifiers: [\(leftVersion.buildMetadataIdentifiers.joined(separator: ", "))]")
                print()
                print("Parsed components of right version:")
                print("\tMajor: \(rightVersion.major)")
                print("\tMinor: \(rightVersion.minor)")
                print("\tPatch: \(rightVersion.patch)")
                print("\tPrerelease identifiers: [\(rightVersion.prereleaseIdentifiers.joined(separator: ", "))]")
                print("\tBuild metadata identifiers: [\(rightVersion.buildMetadataIdentifiers.joined(separator: ", "))]")
                print()
                print("Identifier components of left version as compared according to chosen mode and operation:")
                print("\tPrerelease identifiers: [\(compareLeftVersion.prereleaseIdentifiers.joined(separator: ", "))]")
                print("\tBuild metadata identifiers: [\(compareLeftVersion.buildMetadataIdentifiers.joined(separator: ", "))]")
                print()
                print("Identifier components of right version as compared according to chosen mode and operation:")
                print("\tPrerelease identifiers: [\(compareRightVersion.prereleaseIdentifiers.joined(separator: ", "))]")
                print("\tBuild metadata identifiers: [\(compareRightVersion.buildMetadataIdentifiers.joined(separator: ", "))]")
                print()
                if [leftVersion.major, leftVersion.minor, leftVersion.patch] != [rightVersion.major, rightVersion.minor, rightVersion.patch] {
                    print("The comparison did not depend on any identifiers.")
                } else {
                    // TODO: More debug stuff. This part is where it would actually be interesting anyway...
                }
                print()
                print("The comparsion operation was \"\(operation.verboseDescription)?\"")
                print("The result was: \(result ? "yes" : "no").")
        }
        throw result ? ExitCode.success : ExitCode.failure
    }
}

/// No implementation required, one is presupplied for types conforming to `LosslessStringConvertible`.
extension SemanticVersion: ExpressibleByArgument {}

infix operator ⍃: ComparisonPrecedence

extension SemanticVersion {
    fileprivate static func ⍃(lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let lhsComponents = [lhs.major, lhs.minor, lhs.patch]
        let rhsComponents = [rhs.major, rhs.minor, rhs.patch]

        guard lhsComponents == rhsComponents else {
            return lhsComponents.lexicographicallyPrecedes(rhsComponents)
        }
        
        if lhs.prereleaseIdentifiers.isEmpty { return false } // Non-prerelease lhs >= potentially prerelease rhs
        if rhs.prereleaseIdentifiers.isEmpty { return true } // Prerelease lhs < non-prerelease rhs

        switch zip(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers)
                    .first(where: { $0 != $1 })
                    .map({ ((Int($0) ?? $0) as Any, (Int($1) ?? $1) as Any) })
        {
            case let .some((lId as Int, rId as Int)):       return lId < rId
            case let .some((lId as String, rId as String)): return lId < rId
            case     .some((is Int, _)):                    return true // numeric prerelease identifier always < non-numeric
            case     .some:                                 return false // rhs > lhs
            case     .none:                                 break // all prerelease identifiers are equal
        }
        if lhs.prereleaseIdentifiers.count != rhs.prereleaseIdentifiers.count {
            return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
        }
        
        return lhs.buildMetadataIdentifiers.joined(separator: ".") < rhs.buildMetadataIdentifiers.joined(separator: ".")
    }
}

/// A comparison operation
enum ComparisonOperation: CaseIterable, ExpressibleByArgument {
    case equality, inequality, ascending/* < */, maximal/* <= */, descending/* > */, minimal /* >= */
    
    public init?(argument: String) {
        switch argument {
            case "==", "eq", "equal": self = .equality
            case "!=", "ne", "unequal": self = .inequality
            case "<", "lt", "older": self = .ascending
            case "<=", "le", "notNewer": self = .maximal
            case ">", "gt", "newer": self = .descending
            case ">=", "ge", "notOlder": self = .minimal
            default: return nil
        }
    }
    
    public static var allValueStrings: [String] {
        return ["==", "eq", "equal", "!=", "ne", "unequal", "<", "lt", "older",
                "<=", "le", "notNewer", ">", "gt", "newer", ">=", "ge", "notOlder"]
    }
    
    fileprivate var normalDescription: String {
        switch self {
            case .equality: return "the same as"
            case .inequality: return "different from"
            case .ascending: return "older than"
            case .maximal: return "no newer than"
            case .descending: return "newer than"
            case .minimal: return "no older than"
        }
    }
    
    fileprivate var verboseDescription: String {
        switch self {
            case .equality: return "are the two versions the same"
            case .inequality: return "are the two versions different"
            case .ascending: return "is the first version older than the second"
            case .maximal: return "is the second version at least as new as the first"
            case .descending: return "is the first version newer than the second"
            case .minimal: return "is the second version at least as old as the first"
        }
    }
}

/// A comparison mode informing the behavior of the various operators with respect to prerelease identifiers and build
/// metadata identifiers. The default mode is `.precedence`, as described by the semver spec.
enum CompareOperatorMode: CaseIterable, EnumerableFlag, Equatable {
    case traditional // prerelease identifiers and build metadata identifiers are ignored by all operators
    case precedence // all comparisons, including equality, use the semver precedence rules from the spec; default
    case strictEquality // as `.precedence`, except == and != respect build metadata identifiers
    case strictComparison // causes all operators to respect build metadata identifiers (always compared as strings)
    
    static func name(for value: CompareOperatorMode) -> NameSpecification {
        switch value {
            case .traditional: return .long
            case .precedence: return .long
            case .strictEquality: return .customLong("strict-equality-only")
            case .strictComparison: return [.customLong("strict"), .customLong("build-metadata-is-significant")]
        }
    }
    
    static func help(for value: CompareOperatorMode) -> ArgumentHelp? {
        switch value {
        
        case .traditional: return .init(
            abstract: "Ignore prerelease identifiers and build metadata when comparing version numbers",
            discussion: """
                Comparisons in traditional mode have semantics roughly similar
                to those of `sort -V`; the required three numeric components
                are considered the only sort keys. Prerelease identifiers and
                build metadata are ignored, though they are still parsed.
                """
        )
        
        case .precedence: return .init(
            abstract: "Use the semver 2.0.0 precedence algorithm for comparing version numbers",
            discussion: """
                The default mode. This option exists primarily to allow canceling
                out any of the other mode options and explicitly specifying the
                default algorithm.
                """
        )
        
        case .strictEquality: return .init(
            abstract: "Respect build metadata identifers when determining equality of versions",
            discussion: """
                In this mode, the == and != operators will consider build metadata
                significant. All other operators use the precedence algorithm.
                """
        )
        
        case .strictComparison: return .init(
            abstract: "Respect build metadata identifiers for all version number comparisons",
            discussion: """
                When build metadata identifiers are present, they are compared as
                strings, using the same rules as for string prerelease identifiers.
                A version having build metadata is considered "newer" than an
                equivalent version lacking it when this mode is in effect.
                
                WARNING: This probably isn't what you want.
                """
        )

        }
    }
}

/// A set of predefined behaviors controlling the form of the compare command's output. The default is `.normal`.
enum CompareOutputBehavior: CaseIterable, EnumerableFlag {
    case normal // output a short human-readable response
    case silent // output nothing, just exit with 0 or 1
    case verbose // output a more detailed explanation of the result
    case debug // output parsed forms of both versions and as much info as possible about the compare
    
    static func name(for value: Self) -> NameSpecification {
        switch value {
            case .normal: return .customLong("show-result")
            case .silent: return [.customShort("s"), .customShort("q"), .long]
            case .verbose: return [.customShort("v"), .long]
            case .debug: return .long
        }
    }
    
    static func help(for value: Self) -> ArgumentHelp? {
        switch value {

        case .normal: return .init(
            abstract: "Show the result of the comparison.",
            discussion: """
                This is the default behavior. This option exists primarily to provide a
                means to cancel the effects of the -s, -v, and --debug options, and
                overrides all of them if specified last.
                """)

        case .silent: return .init(
            abstract: "Silent or quiet mode. Suppresses all output.",
            discussion: """
                Consult the process exit status for the result of the comparison. This
                option overrides --show-result, -v, and --debug if specified last.
                """)
        
        case .verbose: return .init(
            abstract: "Outputs additional information about the comparison.",
            discussion: """
                Useful for seeing what logic is used to decide the result of any given
                comparison. This option overrides both -s and --debug if specified last.
                """)
        
        case .debug: return .init(
            abstract: "Enables lots of debug logging about every aspect of a comparison.",
            discussion: """
                Unless you're either debugging this tool or very curious about what's
                going on inside it, this is probably not useful to you. Overrides
                --silent if specified last.
                """)
        }
    }
}
