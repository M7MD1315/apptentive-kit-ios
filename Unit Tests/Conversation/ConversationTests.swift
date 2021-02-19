//
//  ConversationTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 12/9/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class ConversationTests: XCTestCase {

    func testMerge() throws {
        let environment = MockEnvironment()

        let conversation1 = Conversation(environment: environment)
        var conversation2 = Conversation(environment: environment)

        conversation2.person.name = "Testy McTesterson"
        conversation2.appRelease.version = "2"

        XCTAssertNotEqual(conversation1.person.name, conversation2.person.name)
        XCTAssertNotEqual(conversation1.appRelease.version, conversation2.appRelease.version)

        let merged = try conversation1.merged(with: conversation2)

        XCTAssertEqual(merged.person.name, conversation2.person.name)
        XCTAssertEqual(merged.appRelease.version, conversation2.appRelease.version)

        XCTAssertTrue(merged.appRelease.isUpdatedVersion)
    }
}