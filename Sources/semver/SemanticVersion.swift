/// An arbitrary semantic version number, represented as its individual components. This type adheres to the format and
/// behaviors specified by [Semantic Versioning 2.0.0][semver2]. This is the same versioning format used by the Swift
/// Package Manager, and some of this implementation was informed by the one found in SPM. A short summary of the
/// semantics provided by the specification follows.
///
/// [semver2]: https://semver.org/spec/v2.0.0.html
///
/// A semantic version contains three required components (major version, minor version, and patch level). It may
/// optionally contain any number of "prerelease identifier" components; these are often used to represent development
/// stages, such as "alpha", "beta", and "rc". It may also optionally contain any number of build metadata identifiers,
/// which are sometimes used to uniquely identify builds (such as by a timestamp or UUID, or with an architecture name).
///
/// All of a version's components, including both types of identifiers, are considered when determining _equality_ of
/// any two or more semantic versions. This is not the case, however, when determining the precedence of a given version
/// relative to another, where "precedence" refers to the total ordering of semantic versions. The semver specification
/// provides a detailed algorithm for making this determination. The most notable difference between this algorithm and
/// an equality comparison is that precedence does not consider build metadata identifiers; this behavior may be
/// observable via, e.g., the results of applying a sorting algorithm.
public struct SemanticVersion: Hashable {
    /// The major version number.
    public let major: UInt

    /// The minor version number.
    public let minor: UInt

    /// The patch level number.
    public let patch: UInt

    /// The prerelease identifiers.
    public let prereleaseIdentifiers: [String]

    /// The build metadata identifiers.
    public let buildMetadataIdentifiers: [String]

    /// Create a semantic version from the individual components.
    public init(
        _ major: UInt,
        _ minor: UInt,
        _ patch: UInt,
        prereleaseIdentifiers: [String] = [],
        buildMetadataIdentifiers: [String] = []
    ) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prereleaseIdentifiers
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }

    /// Create a semantic version from a provided string, parsing it according to spec.
    ///
    /// - Returns: `nil` if the provided string is not a valid semantic version.
    ///
    /// - TODO: Possibly throw more specific validation errors? Would this be useful?
    public init?(string: String) {
        guard string.firstIndex(where: { !$0.isASCII }) == nil else { return nil }
        
        let prereleaseStartIndex = string.firstIndex(of: "-")
        let metadataStartIndex = string.firstIndex(of: "+")
        
        if let pidx = prereleaseStartIndex, let midx = metadataStartIndex, midx <= pidx {
            // + appears before - in string, invalid syntax
            return nil
        }

        let requiredEndIndex = prereleaseStartIndex ?? metadataStartIndex ?? string.endIndex
        let requiredCharacters = string.prefix(upTo: requiredEndIndex)
        let requiredComponents = requiredCharacters
            .split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false).compactMap { UInt($0) }

        guard requiredComponents.count == 3 else { return nil }
        
        self.major = requiredComponents[0]
        self.minor = requiredComponents[1]
        self.patch = requiredComponents[2]

        func identifiers(start: String.Index, end: String.Index? = nil) -> [String] {
            return string[string.index(after: start) ..< (end ?? string.endIndex)].split(separator: ".").map(String.init)
        }
        self.prereleaseIdentifiers = prereleaseStartIndex.map { identifiers(start: $0, end: metadataStartIndex) } ?? []
        self.buildMetadataIdentifiers = metadataStartIndex.map { identifiers(start: $0) } ?? []
    }
}

extension SemanticVersion: Comparable {
    /// See `Comparable.<(lhs:rhs:)`. Implements the "precedence" ordering specified by the semver specification.
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
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

        return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
    }
}

extension SemanticVersion: LosslessStringConvertible {
    /// See `CustomStringConvertible.description`. An additional API guarantee is made that this property will always
    /// yield a string which is correctly formatted as a valid semantic version number.
    public var description: String {
        return """
            \(major).\
            \(minor).\
            \(patch)\
            \(prereleaseIdentifiers.joined(separator: ".", prefix: "-"))\
            \(buildMetadataIdentifiers.joined(separator: ".", prefix: "+"))
            """
    }
    
    /// See `LosslessStringConvertible.init(_:)`. The semantics are identical to those of `init?(string:)`.
    public init?(_ description: String) {
        self.init(string: description)
    }
}

extension SemanticVersion: Codable {
    /// See `Encodable.encode(to:)`.
    public func encode(to encoder: Encoder) throws {
        try self.description.encode(to: encoder)
    }

    /// See `Decodable.init(from:)`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        guard let version = SemanticVersion(string: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid semantic version: \(raw)")
        }
        self = version
    }
}

fileprivate extension Array where Element == String {
    /// Identical to `joined(separator:)`, except that when the result is non-empty, the provided `prefix` will be
    /// prepended to it. This is a mildly silly solution to the issue of how best to implement "add a joiner character
    /// between one interpolation and the next, but only if the second one is non-empty".
    func joined(separator: String, prefix: String) -> String {
        let result = self.joined(separator: separator)
        return (result.isEmpty ? "" : prefix) + result
    }
}
