//
//  AppUserDefaults.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
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

import Foundation
import Core
import WidgetKit

public class AppUserDefaults: AppSettings {
    
    public struct Notifications {
        public static let doNotSellStatusChange = Notification.Name("com.duckduckgo.app.DoNotSellStatusChange")
        public static let currentFireButtonAnimationChange = Notification.Name("com.duckduckgo.app.CurrentFireButtonAnimationChange")
        public static let textSizeChange = Notification.Name("com.duckduckgo.app.TextSizeChange")
        public static let autofillEnabledChange = Notification.Name("com.duckduckgo.app.AutofillEnabledChange")
        public static let didVerifyInternalUser = Notification.Name("com.duckduckgo.app.DidVerifyInternalUser")
    }

    private let groupName: String

    private struct Keys {
        static let autocompleteKey = "com.duckduckgo.app.autocompleteDisabledKey"
        static let currentThemeNameKey = "com.duckduckgo.app.currentThemeNameKey"
        
        static let autoClearActionKey = "com.duckduckgo.app.autoClearActionKey"
        static let autoClearTimingKey = "com.duckduckgo.app.autoClearTimingKey"
        
        static let homePage = "com.duckduckgo.app.homePage"

        static let foregroundFetchStartCount = "com.duckduckgo.app.fgFetchStartCount"
        static let foregroundFetchNoDataCount = "com.duckduckgo.app.fgFetchNoDataCount"
        static let foregroundFetchNewDataCount = "com.duckduckgo.app.fgFetchNewDataCount"
        
        static let backgroundFetchStartCount = "com.duckduckgo.app.bgFetchStartCount"
        static let backgroundFetchNoDataCount = "com.duckduckgo.app.bgFetchNoDataCount"
        static let backgroundFetchNewDataCount = "com.duckduckgo.app.bgFetchNewDataCount"

        static let backgroundFetchTaskExpirationCount = "com.duckduckgo.app.bgFetchTaskExpirationCount"
        
        static let notificationsEnabled = "com.duckduckgo.app.notificationsEnabled"
        static let allowUniversalLinks = "com.duckduckgo.app.allowUniversalLinks"
        static let longPressPreviews = "com.duckduckgo.app.longPressPreviews"
        
        static let currentFireButtonAnimationKey = "com.duckduckgo.app.currentFireButtonAnimationKey"
        
        static let autofillCredentialsEnabled = "com.duckduckgo.ios.autofillCredentialsEnabled"
    }

    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: groupName)
    }

    init(groupName: String =  "group.com.duckduckgo.app") {
        self.groupName = groupName
    }

    var autocomplete: Bool {

        get {
            return userDefaults?.bool(forKey: Keys.autocompleteKey, defaultValue: true) ?? true
        }

        set {
            userDefaults?.setValue(newValue, forKey: Keys.autocompleteKey)
        }

    }
    
    var currentThemeName: ThemeName {
        
        get {
            var currentThemeName: ThemeName?
            if let stringName = userDefaults?.string(forKey: Keys.currentThemeNameKey) {
                currentThemeName = ThemeName(rawValue: stringName)
            }
            
            if let themeName = currentThemeName {
                return themeName
            } else {
                return .systemDefault
            }
        }
        
        set {
            userDefaults?.setValue(newValue.rawValue, forKey: Keys.currentThemeNameKey)
        }
        
    }
    
    var autoClearAction: AutoClearSettingsModel.Action {
        
        get {
            let value = userDefaults?.integer(forKey: Keys.autoClearActionKey) ?? 0
            return AutoClearSettingsModel.Action(rawValue: value)
        }
        
        set {
            userDefaults?.setValue(newValue.rawValue, forKey: Keys.autoClearActionKey)
        }
        
    }
    
    var autoClearTiming: AutoClearSettingsModel.Timing {
        
        get {
            if let rawValue = userDefaults?.integer(forKey: Keys.autoClearTimingKey),
                let value = AutoClearSettingsModel.Timing(rawValue: rawValue) {
                return value
            }
            return .termination
        }
        
        set {
            userDefaults?.setValue(newValue.rawValue, forKey: Keys.autoClearTimingKey)
        }
        
    }
    
    var allowUniversalLinks: Bool {
        get {
            return userDefaults?.object(forKey: Keys.allowUniversalLinks) as? Bool ?? true
        }
        
        set {
            userDefaults?.set(newValue, forKey: Keys.allowUniversalLinks)
        }
    }

    var longPressPreviews: Bool {
        get {
            return userDefaults?.object(forKey: Keys.longPressPreviews) as? Bool ?? true
        }

        set {
            userDefaults?.set(newValue, forKey: Keys.longPressPreviews)
        }
    }
    
    @UserDefaultsWrapper(key: .doNotSell, defaultValue: true)
    var sendDoNotSell: Bool
    
    var currentFireButtonAnimation: FireButtonAnimationType {
        get {
            if let string = userDefaults?.string(forKey: Keys.currentFireButtonAnimationKey),
               let currentAnimation = FireButtonAnimationType(rawValue: string) {
                
                return currentAnimation
            } else {
                return .fireRising
            }
        }
        set {
            userDefaults?.setValue(newValue.rawValue, forKey: Keys.currentFireButtonAnimationKey)
        }
    }
    
    @UserDefaultsWrapper(key: .textSize, defaultValue: 100)
    var textSize: Int

    private func setAutofillCredentialsEnabledAutomaticallyIfNecessary() {
        if autofillCredentialsHasBeenEnabledAutomaticallyIfNecessary {
            return
        }
        if !autofillCredentialsSavePromptShowAtLeastOnce {
            autofillCredentialsHasBeenEnabledAutomaticallyIfNecessary = true
            autofillCredentialsEnabled = true
        }
    }
    
    var autofillCredentialsEnabled: Bool {
        get {
            // In future, we'll use setAutofillCredentialsEnabledAutomaticallyIfNecessary() here to automatically turn on autofill for people
            // That haven't seen the save prompt before.
            // For now, whilst internal testing is still happening, it's still set to default to be enabled
            return userDefaults?.object(forKey: Keys.autofillCredentialsEnabled) as? Bool ?? true
        }
        
        set {
            userDefaults?.set(newValue, forKey: Keys.autofillCredentialsEnabled)
        }
    }
    
    @UserDefaultsWrapper(key: .autofillCredentialsSavePromptShowAtLeastOnce, defaultValue: false)
    var autofillCredentialsSavePromptShowAtLeastOnce: Bool
    
    @UserDefaultsWrapper(key: .autofillCredentialsHasBeenEnabledAutomaticallyIfNecessary, defaultValue: false)
    var autofillCredentialsHasBeenEnabledAutomaticallyIfNecessary: Bool
    
    @UserDefaultsWrapper(key: .voiceSearchEnabled, defaultValue: false)
    var voiceSearchEnabled: Bool

    func isWidgetInstalled() async -> Bool {
        return await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let configurations):
                    continuation.resume(returning: configurations.count > 0)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    @UserDefaultsWrapper(key: .autoconsentPromptSeen, defaultValue: false)
    var autoconsentPromptSeen: Bool
    
    @UserDefaultsWrapper(key: .autoconsentEnabled, defaultValue: false)
    var autoconsentEnabled: Bool
    
    @UserDefaultsWrapper(key: .wasFireButtonEverTapped, defaultValue: false)
    var wasFireButtonEverTapped: Bool
    
    @UserDefaultsWrapper(key: .wasFireButtonEducationRestarted, defaultValue: false)
    var wasFireButtonEducationRestarted: Bool
}

extension AppUserDefaults: AppConfigurationFetchStatistics {
    
    var foregroundStartCount: Int {
        get {
            return userDefaults?.integer(forKey: Keys.foregroundFetchStartCount) ?? 0
        }
        set {
            userDefaults?.setValue(newValue, forKey: Keys.foregroundFetchStartCount)
        }
    }
    
    var foregroundNoDataCount: Int {
        get {
            return userDefaults?.integer(forKey: Keys.foregroundFetchNoDataCount) ?? 0
        }
        set {
            userDefaults?.setValue(newValue, forKey: Keys.foregroundFetchNoDataCount)
        }
    }
    
    var foregroundNewDataCount: Int {
        get {
            return userDefaults?.integer(forKey: Keys.foregroundFetchNewDataCount) ?? 0
        }
        set {
            userDefaults?.setValue(newValue, forKey: Keys.foregroundFetchNewDataCount)
        }
    }
    
    var backgroundStartCount: Int {
        get {
            return userDefaults?.integer(forKey: Keys.backgroundFetchStartCount) ?? 0
        }
        set {
            userDefaults?.setValue(newValue, forKey: Keys.backgroundFetchStartCount)
        }
    }
    
    var backgroundNoDataCount: Int {
        get {
            return userDefaults?.integer(forKey: Keys.backgroundFetchNoDataCount) ?? 0
        }
        set {
            userDefaults?.setValue(newValue, forKey: Keys.backgroundFetchNoDataCount)
        }
    }
    
    var backgroundNewDataCount: Int {
        get {
            return userDefaults?.integer(forKey: Keys.backgroundFetchNewDataCount) ?? 0
        }
        set {
            userDefaults?.setValue(newValue, forKey: Keys.backgroundFetchNewDataCount)
        }
    }

    var backgroundFetchTaskExpirationCount: Int {
        get {
            return userDefaults?.integer(forKey: Keys.backgroundFetchTaskExpirationCount) ?? 0
        }
        set {
            userDefaults?.setValue(newValue, forKey: Keys.backgroundFetchTaskExpirationCount)
        }
    }
}
