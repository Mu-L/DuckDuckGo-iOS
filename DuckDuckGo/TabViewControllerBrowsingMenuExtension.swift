//
//  TabViewControllerBrowsingMenuExtension.swift
//  DuckDuckGo
//
//  Copyright © 2018 DuckDuckGo. All rights reserved.
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

import UIKit
import Core
import BrowserServicesKit
import Bookmarks
import simd
import WidgetKit

// swiftlint:disable file_length
extension TabViewController {
    
    func buildBrowsingMenuHeaderContent() -> [BrowsingMenuEntry] {
        
        var entries = [BrowsingMenuEntry]()
        
        entries.append(BrowsingMenuEntry.regular(name: UserText.actionNewTab,
                                                 accessibilityLabel: UserText.keyCommandNewTab,
                                                 image: UIImage(named: "MenuNewTab")!,
                                                 action: { [weak self] in
            self?.onNewTabAction()
        }))
        
        entries.append(BrowsingMenuEntry.regular(name: UserText.actionShare, image: UIImage(named: "MenuShare")!, action: { [weak self] in
            guard let self = self else { return }
            guard let menu = self.chromeDelegate?.omniBar.menuButton else { return }
            self.onShareAction(forLink: self.link!, fromView: menu, orginatedFromMenu: true)
        }))
        
        entries.append(BrowsingMenuEntry.regular(name: UserText.actionCopy, image: UIImage(named: "MenuCopy")!, action: { [weak self] in
            guard let strongSelf = self else { return }
            if !strongSelf.isError, let url = strongSelf.webView.url {
                strongSelf.onCopyAction(forUrl: url)
            } else if let text = self?.chromeDelegate?.omniBar.textField.text {
                strongSelf.onCopyAction(for: text)
            }
            
            Pixel.fire(pixel: .browsingMenuCopy)
            ActionMessageView.present(message: UserText.actionCopyMessage)
        }))
        
        entries.append(BrowsingMenuEntry.regular(name: UserText.actionPrint, image: UIImage(named: "MenuPrint")!, action: { [weak self] in
            Pixel.fire(pixel: .browsingMenuPrint)
            self?.print()
        }))

        return entries
    }
    
    var favoriteEntryIndex: Int { 1 }

    func buildBrowsingMenu(with bookmarksInterface: MenuBookmarksInteracting) -> [BrowsingMenuEntry] {
        var entries = [BrowsingMenuEntry]()
        
        let linkEntries = buildLinkEntries(with: bookmarksInterface)
        entries.append(contentsOf: linkEntries)
            
        if let domain = self.privacyInfo?.domain {
            entries.append(self.buildToggleProtectionEntry(forDomain: domain))
        }

        entries.append(BrowsingMenuEntry.regular(name: UserText.actionReportBrokenSite,
                                                 image: UIImage(named: "MenuFeedback")!,
                                                 action: { [weak self] in
            self?.onReportBrokenSiteAction()
        }))

        entries.append(.separator)

        if self.featureFlagger.isFeatureOn(.autofill) {
            entries.append(BrowsingMenuEntry.regular(name: UserText.actionAutofillLogins,
                                                     image: UIImage(named: "MenuAutofill")!,
                                                     action: { [weak self] in
                self?.onOpenAutofillLoginsAction()
            }))
        }

        entries.append(BrowsingMenuEntry.regular(name: UserText.actionDownloads,
                                                 image: UIImage(named: "MenuDownloads")!,
                                                 showNotificationDot: AppDependencyProvider.shared.downloadManager.unseenDownloadsAvailable,
                                                 action: { [weak self] in
            self?.onOpenDownloadsAction()
        }))

        entries.append(BrowsingMenuEntry.regular(name: UserText.actionSettings,
                                                 image: UIImage(named: "MenuSettings")!,
                                                 action: { [weak self] in
            self?.onBrowsingSettingsAction()
        }))

        return entries
    }

    private func buildLinkEntries(with bookmarksInterface: MenuBookmarksInteracting) -> [BrowsingMenuEntry] {
        guard let link = link, !isError else { return [] }

        var entries = [BrowsingMenuEntry]()

        let bookmarkEntries = buildBookmarkEntries(for: link, with: bookmarksInterface)
        entries.append(bookmarkEntries.bookmark)
        assert(self.favoriteEntryIndex == entries.count, "Entry index should be in sync with entry placement")
        entries.append(bookmarkEntries.favorite)
                
        entries.append(BrowsingMenuEntry.regular(name: UserText.actionOpenBookmarks,
                                                 image: UIImage(named: "MenuBookmarks")!,
                                                 action: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.tabDidRequestBookmarks(tab: strongSelf)
        }))

        entries.append(.separator)

        if let entry = self.buildKeepSignInEntry(forLink: link) {
            entries.append(entry)
        }

        if let entry = self.buildUseNewDuckAddressEntry(forLink: link) {
            entries.append(entry)
        }

        let title = self.tabModel.isDesktop ? UserText.actionRequestMobileSite : UserText.actionRequestDesktopSite
        let image = self.tabModel.isDesktop ? UIImage(named: "MenuMobileMode")! : UIImage(named: "MenuDesktopMode")!
        entries.append(BrowsingMenuEntry.regular(name: title, image: image, action: { [weak self] in
            self?.onToggleDesktopSiteAction(forUrl: link.url)
        }))

        entries.append(self.buildFindInPageEntry(forLink: link))
                
        return entries
    }
    
    private func buildKeepSignInEntry(forLink link: Link) -> BrowsingMenuEntry? {
        guard let domain = link.url.host, !link.url.isDuckDuckGo else { return nil }
        let isFireproofed = PreserveLogins.shared.isAllowed(cookieDomain: domain)
        
        if isFireproofed {
            return BrowsingMenuEntry.regular(name: UserText.disablePreservingLogins,
                                             image: UIImage(named: "MenuRemoveFireproof")!,
                                             action: { [weak self] in
                                                self?.disableFireproofingForDomain(domain)
                                             })
        }

        return BrowsingMenuEntry.regular(name: UserText.enablePreservingLogins,
                                         image: UIImage(named: "MenuFireproof")!,
                                         action: { [weak self] in
                                            self?.enableFireproofingForDomain(domain)
                                         })
    }

    private func onNewTabAction() {
        Pixel.fire(pixel: .browsingMenuNewTab)
        delegate?.tabDidRequestNewTab(self)
    }

    private func buildFindInPageEntry(forLink link: Link) -> BrowsingMenuEntry {
        return BrowsingMenuEntry.regular(name: UserText.findInPage, image: UIImage(named: "MenuFind")!, action: { [weak self] in
            Pixel.fire(pixel: .browsingMenuFindInPage)
            self?.requestFindInPage()
        })
    }
    
    private func buildBookmarkEntries(for link: Link,
                                      with bookmarksInterface: MenuBookmarksInteracting) -> (bookmark: BrowsingMenuEntry,
                                                                                             favorite: BrowsingMenuEntry) {
        let existingFavorite = bookmarksInterface.favorite(for: link.url)
        let existingBookmark = existingFavorite ?? bookmarksInterface.bookmark(for: link.url)
        
        return (bookmark: buildBookmarkEntry(for: link,
                                             bookmark: existingBookmark,
                                             with: bookmarksInterface),
                favorite: buildFavoriteEntry(for: link,
                                             bookmark: existingFavorite,
                                             with: bookmarksInterface))
    }

    private func buildBookmarkEntry(for link: Link,
                                    bookmark: BookmarkEntity?,
                                    with bookmarksInterface: MenuBookmarksInteracting) -> BrowsingMenuEntry {
        
        if bookmark != nil {
            return BrowsingMenuEntry.regular(name: UserText.actionEditBookmark,
                                             image: UIImage(named: "MenuBookmarkSolid")!,
                                             action: { [weak self] in
                                                self?.performEditBookmarkAction(for: link)
                                             })
        }

        return BrowsingMenuEntry.regular(name: UserText.actionSaveBookmark,
                                         image: UIImage(named: "MenuBookmark")!,
                                         action: { [weak self] in
                                           self?.performSaveBookmarkAction(for: link,
                                                                           with: bookmarksInterface)
                                         })
    }

    private func performSaveBookmarkAction(for link: Link,
                                           with bookmarksInterface: MenuBookmarksInteracting) {
        Pixel.fire(pixel: .browsingMenuAddToBookmarks)
        bookmarksInterface.createBookmark(title: link.title ?? "", url: link.url)
        favicons.loadFavicon(forDomain: link.url.host, intoCache: .bookmarks, fromCache: .tabs)

        ActionMessageView.present(message: UserText.webSaveBookmarkDone,
                                  actionTitle: UserText.actionGenericEdit, onAction: {
            self.performEditBookmarkAction(for: link)
        })
    }

    private func performEditBookmarkAction(for link: Link) {
        Pixel.fire(pixel: .browsingMenuEditBookmark)

        delegate?.tabDidRequestEditBookmark(tab: self)
    }

    private func buildFavoriteEntry(for link: Link,
                                    bookmark: BookmarkEntity?,
                                    with bookmarksInterface: MenuBookmarksInteracting) -> BrowsingMenuEntry {
        if bookmark?.isFavorite ?? false {
            let action: () -> Void = { [weak self] in
                Pixel.fire(pixel: .browsingMenuRemoveFromFavorites)
                self?.performRemoveFavoriteAction(for: link, with: bookmarksInterface)
            }

            let entry = BrowsingMenuEntry.regular(name: UserText.actionRemoveFavorite,
                                                  image: UIImage(named: "MenuFavoriteSolid")!,
                                                  action: action)
            return entry

        }

        // Capture flow state here as will be reset after menu is shown
        let addToFavoriteFlow = DaxDialogs.shared.isAddFavoriteFlow

        let entry = BrowsingMenuEntry.regular(name: UserText.actionSaveFavorite,
                                              image: UIImage(named: "MenuFavorite")!,
                                              action: { [weak self] in
            Pixel.fire(pixel: addToFavoriteFlow ? .browsingMenuAddToFavoritesAddFavoriteFlow : .browsingMenuAddToFavorites)
            self?.performAddFavoriteAction(for: link, with: bookmarksInterface)
        })
        return entry
    }
    
    private func performAddFavoriteAction(for link: Link,
                                          with bookmarksInterface: MenuBookmarksInteracting) {
        bookmarksInterface.createOrToggleFavorite(title: link.title ?? "", url: link.url)
        favicons.loadFavicon(forDomain: link.url.host, intoCache: .bookmarks, fromCache: .tabs)
        WidgetCenter.shared.reloadAllTimelines()
        
        ActionMessageView.present(message: UserText.webSaveFavoriteDone, actionTitle: UserText.actionGenericUndo, onAction: {
            self.performRemoveFavoriteAction(for: link, with: bookmarksInterface)
        })
    }
    
    private func performRemoveFavoriteAction(for link: Link,
                                             with bookmarksInterface: MenuBookmarksInteracting) {
        bookmarksInterface.createOrToggleFavorite(title: link.title ?? "", url: link.url)
        WidgetCenter.shared.reloadAllTimelines()
        
        ActionMessageView.present(message: UserText.webFavoriteRemoved, actionTitle: UserText.actionGenericUndo, onAction: {
            self.performAddFavoriteAction(for: link, with: bookmarksInterface)
        })
    }
    
    private func buildUseNewDuckAddressEntry(forLink link: Link) -> BrowsingMenuEntry? {
        guard emailManager.isSignedIn else { return nil }
        let title = UserText.emailBrowsingMenuUseNewDuckAddress
        let image = UIImage(named: "MenuEmail")!

        return BrowsingMenuEntry.regular(name: title, image: image) { [weak self] in
            guard let emailManager = self?.emailManager else { return }

            var pixelParameters: [String: String] = [:]

            if let cohort = emailManager.cohort {
                pixelParameters[PixelParameters.emailCohort] = cohort
            }
            pixelParameters[PixelParameters.emailLastUsed] = emailManager.lastUseDate
            emailManager.updateLastUseDate()

            Pixel.fire(pixel: .emailUserCreatedAlias, withAdditionalParameters: pixelParameters, includedParameters: [])

            emailManager.getAliasIfNeededAndConsume { alias, _ in
                Task { @MainActor in
                    guard let alias = alias else {
                        // we may want to communicate this failure to the user in the future
                        return
                    }
                    let pasteBoard = UIPasteboard.general
                    pasteBoard.string = emailManager.emailAddressFor(alias)
                    ActionMessageView.present(message: UserText.emailBrowsingMenuAlert)
                }
            }
        }
    }

    func onShareAction(forLink link: Link, fromView view: UIView, orginatedFromMenu: Bool) {
        Pixel.fire(pixel: .browsingMenuShare,
                   withAdditionalParameters: [PixelParameters.originatedFromMenu: orginatedFromMenu ? "1" : "0"])
        
        shareLinkWithTemporaryDownload(temporaryDownloadForPreviewedFile, originalLink: link) { [weak self] link in
            guard let self = self else { return }
            self.presentShareSheet(withItems: [ link, self.webView.viewPrintFormatter() ], fromView: view)
        }
    }
    
    private func shareLinkWithTemporaryDownload(_ temporaryDownload: Download?,
                                                originalLink: Link,
                                                completion: @escaping(Link) -> Void) {
        guard let download = temporaryDownload else {
            completion(originalLink)
            return
        }
        
        if let downloadLink = download.link {
            completion(downloadLink)
            return
        }
        
        AppDependencyProvider.shared.downloadManager.startDownload(download) { error in
            DispatchQueue.main.async {
                if error == nil, let downloadLink = download.link {
                    let fileSize = downloadLink.localFileURL?.fileSize ?? 0
                    let isFileSizeGreaterThan10MB = (fileSize > 10 * 1000 * 1000)
                    Pixel.fire(pixel: .downloadsSharingPredownloadedLocalFile,
                               withAdditionalParameters: [PixelParameters.fileSizeGreaterThan10MB: isFileSizeGreaterThan10MB ? "1" : "0"])
                    completion(downloadLink)
                } else {
                    completion(originalLink)
                }
            }
        }
    }
    
    private func onToggleDesktopSiteAction(forUrl url: URL) {
        Pixel.fire(pixel: .browsingMenuToggleBrowsingMode)
        tabModel.toggleDesktopMode()
        updateContentMode()
        
        if tabModel.isDesktop {
            load(url: url.toDesktopUrl())
        } else {
            reload()
        }
    }
    
    private func onReportBrokenSiteAction() {
        Pixel.fire(pixel: .browsingMenuReportBrokenSite)
        delegate?.tabDidRequestReportBrokenSite(tab: self)
    }
    
    private func onOpenDownloadsAction() {
        Pixel.fire(pixel: .downloadsListOpened,
                   withAdditionalParameters: [PixelParameters.originatedFromMenu: "1"])
        delegate?.tabDidRequestDownloads(tab: self)
    }
    
    private func onOpenAutofillLoginsAction() {
        Pixel.fire(pixel: .browsingMenuAutofill)
        delegate?.tabDidRequestAutofillLogins(tab: self)
    }
    
    private func onBrowsingSettingsAction() {
        Pixel.fire(pixel: .browsingMenuSettings)
        delegate?.tabDidRequestSettings(tab: self)
    }
    
    private func buildToggleProtectionEntry(forDomain domain: String) -> BrowsingMenuEntry {
        let config = ContentBlocking.shared.privacyConfigurationManager.privacyConfig
        let isProtected = !config.isUserUnprotected(domain: domain)
        let title = isProtected ? UserText.actionDisableProtection : UserText.actionEnableProtection
        let image = isProtected ? UIImage(named: "MenuDisableProtection")! : UIImage(named: "MenuEnableProtection")!
    
        return BrowsingMenuEntry.regular(name: title, image: image, action: { [weak self] in
            Pixel.fire(pixel: isProtected ? .browsingMenuDisableProtection : .browsingMenuEnableProtection)
            self?.togglePrivacyProtection(domain: domain)
        })
    }
    
    private func togglePrivacyProtection(domain: String) {
        let config = ContentBlocking.shared.privacyConfigurationManager.privacyConfig
        let isProtected = !config.isUserUnprotected(domain: domain)
        if isProtected {
            config.userDisabledProtection(forDomain: domain)
        } else {
            config.userEnabledProtection(forDomain: domain)
        }
        
        let message: String
        if isProtected {
            message = UserText.messageProtectionDisabled.format(arguments: domain)
        } else {
            message = UserText.messageProtectionEnabled.format(arguments: domain)
        }
        
        ContentBlocking.shared.contentBlockingManager.scheduleCompilation()
        
        ActionMessageView.present(message: message, actionTitle: UserText.actionGenericUndo, onAction: { [weak self] in
            self?.togglePrivacyProtection(domain: domain)
        })
    }
}
