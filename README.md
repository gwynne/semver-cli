# semver-cli

A simple commandline tool which provides comparison and sorting behaviors according to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html). Try `semver --help` for basic usage information.

## Very early usage

```json
$ semver parse --output-format=json 0.1.0-alpha.1+macos
{
  "major" : 0,
  "prereleaseIdentifiers" : [
    "alpha",
    "1"
  ],
  "patch" : 0,
  "minor" : 1,
  "buildMetadata" : [
    "macos"
  ]
}
```
```
$ semver compare --verbose 0.1.0-alpha.1+macos eq 0.1.0-alpha.1+linux
0.1.0-alpha.1+macos was compared as if it were "0.0.0-alpha.1".
0.1.0-alpha.1+linux was compared as if it were "0.0.0-alpha.1"
The comparsion operation was "are the two versions the same?"
The result was: yes.
```
```
$ semver compare -q 0.1.0-alpha.1+macos eq 0.1.0-alpha.2+linux; echo $?
1
```

The `compare` command implements `==`, `!=`, `<`, `<=`, `>`, and `>=` operators. By default, the comparison is performed according to the precedence algorithm given in the Semver spec, but "traditional" (major/minor/patch only) and "strict" (don't ignore build identifiers) modes are also available. See `semver compare --help` for more information. (Yes, the help is a mess and difficult to make much sense of at the moment. This will be fixed later.)

## Known issues

- Lots and lots and lots.
- Shorthand versions like "1.0" are not currently supported.
- The help for the `compare` command is a mess.
- The `xml` mode of `parse` isn't implemented.
- There's no `construct` command for building a version string from components.
- There's no `extract` command to read individual components.
- There's no `increment` comamnd (bump a specific component).
- There's no switch to say "parse build metadata using `+` separators", only strict semver spec format using dots works.
- The `json` mode of `parse` has no "do/don't pretty-print" switch.
- The `--debug` mode of `compare` doesn't debug the most interesting part of comparisons.
- The phrasing of what the compare operators mean is scattered. There's like six different ways that we say "less than or equal to" and "greater than or equal to" in the different parts of the help and the code. Yes, `<=` is `le` and `notGreater` and `isMaximalRelativeTo` and so forth but we really need to pick a way of expressing the relationship and stick to it. Should we use "newer" and "older" as per traditional with versions, numeric greater/lesser terms as the "precedence" algorithm sort of suggests, etc.?
- There's more, promise.
