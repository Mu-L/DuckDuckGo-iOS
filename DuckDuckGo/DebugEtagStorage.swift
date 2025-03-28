//
//  DebugEtagStorage.swift
//  DuckDuckGo
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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

import Core
import os
import Configuration

/// Only intended for use via Debug screens.
class DebugEtagStorage {

    lazy var defaults = UserDefaults(suiteName: "com.duckduckgo.blocker-list.etags")

    func loadEtag(for storeKey: String) -> String? {
        let etag = defaults?.string(forKey: storeKey)
        os_log("stored etag for %s %s", log: .generalLog, type: .debug, storeKey, etag ?? "nil")
        return etag
    }

    func resetAll() {
        Configuration.allCases.forEach {
            defaults?.removeObject(forKey: $0.storeKey)
        }
    }

}
