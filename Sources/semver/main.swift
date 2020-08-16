import ArgumentParser

extension ArgumentHelp {
    /// A trivial delegating initializer which provides an argument label for the `abstract` parameter. This improves
    /// the formatting of some of the code that makes `ArgumentHelp` values.
    public init(
        abstract: String = "",
        discussion: String = "",
        valueName: String? = nil,
        shouldDisplay: Bool = true
    ) {
        self.init(abstract, discussion: discussion, valueName: valueName, shouldDisplay: shouldDisplay)
    }
}

struct Semver: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for performing various operations on semantic versions",
        subcommands: [CompareCommand.self, ParseCommand.self],
        defaultSubcommand: ParseCommand.self
    )
}

Semver.main()
