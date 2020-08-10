import XCTest

import semverTests

var tests = [XCTestCaseEntry]()
tests += semverTests.allTests()
XCTMain(tests)
