// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    // Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

    import Foundation

    public struct ComponentColor {
        public enum Key: CaseIterable {
            case background
            case text
            case stroke
        }

        public var collection: [Key: SelectedColor] = {
            var collection = [Key: SelectedColor]()

            collection[.background] = SelectedColor(
                selected: SPFKColor.controlActiveBackgroundColor.value(for: .dark),
                unselected: SPFKColor.controlAlphaBackgroundColor.value(for: .dark)
            )

            collection[.text] = SelectedColor(
                selected: SPFKColor.selectedTextColor.value(for: .dark),
                unselected: SPFKColor.textColor.value(for: .dark)
            )

            collection[.stroke] = SelectedColor(
                selected: SPFKColor.controlAccentColor.value(for: .dark),
                unselected: SPFKColor.controlAlphaBackgroundColor.value(for: .dark)
            )

            return collection
        }()

        public subscript(key: Key) -> SelectedColor {
            get { collection[key] ?? SelectedColor() }
            set {
                collection[key] = newValue
            }
        }

        public init() {}
    }

#endif
