// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit
    import Foundation
    import SPFKBase
    import SPFKTesting
    import Testing

    @testable import SPFKUtils

    @Suite
    final class NavigationHistoryTests: TestCaseModel {
        private func node(_ title: String) -> OutlineNode {
            OutlineNode(
                title: title,
                isEditable: true,
                symbolName: nil,
                nodeIdentifier: .init(parentId: UUID(), id: UUID())
            )
        }

        @Test func clearLeavesNoNavigationInEitherDirection() {
            var history = NavigationHistory()
            history.append([node("A")])
            history.append([node("B")])
            _ = history.back()

            #expect(history.canGoBack == false)
            #expect(history.canGoForward == true)

            history.clear()

            #expect(history.canGoBack == false)
            #expect(history.canGoForward == false)
        }

        @Test func appendAfterClearStartsAFreshForwardStack() {
            var history = NavigationHistory()
            history.append([node("A")])
            history.append([node("B")])
            _ = history.back()
            history.clear()

            history.append([node("C")])

            #expect(history.canGoForward == false)
            #expect(history.canGoBack == false)
            #expect(history.back() == nil)
        }
    }
#endif
