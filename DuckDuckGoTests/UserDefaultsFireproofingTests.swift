//
//  UserDefaultsFireproofingTests.swift
//  UnitTests
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import Core

class UserDefaultsFireproofingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupUserDefault(with: #file)
        UserDefaultsWrapper<Any>.clearAll()
    }
    
    func testWhenAllowedDomainsContainsFireproofedDomainThenReturnsTrue() {
        let fireproofing = UserDefaultsFireproofing()
        XCTAssertFalse(fireproofing.isAllowed(fireproofDomain: "example.com"))
        fireproofing.addToAllowed(domain: "example.com")
        XCTAssertTrue(fireproofing.isAllowed(fireproofDomain: "example.com"))
    }
    
    func testWhenNewThenAllowedDomainsIsEmpty() {
        let fireproofing = UserDefaultsFireproofing()
        XCTAssertTrue(fireproofing.allowedDomains.isEmpty)
    }

}