// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import Foundation

    public struct CustomComponentColor {
        public enum Key: CaseIterable {
            case background
            case text
            case stroke
        }

        public var collection: [Key: StateColor] = {
            var collection = [Key: StateColor]()

            collection[.background] = StateColor(
                selected: SPFKColor.controlActiveBackgroundColor.nsColor,
                unselected: SPFKColor.controlAlphaBackgroundColor.nsColor,
                disabled: SPFKColor.controlAlphaBackgroundColor.nsColor
            )

            collection[.text] = StateColor(
                selected: SPFKColor.selectedLabelColor.nsColor,
                unselected: SPFKColor.labelColor.nsColor,
                disabled: SPFKColor.disabledLabelColor.nsColor
            )

            collection[.stroke] = StateColor(
                selected: SPFKColor.controlAccentColor.nsColor,
                unselected: SPFKColor.controlAlphaBackgroundColor.nsColor,
                disabled: SPFKColor.controlAlphaBackgroundColor.nsColor
            )

            return collection
        }()

        public subscript(key: Key) -> StateColor {
            get { collection[key] ?? StateColor() }
            set {
                collection[key] = newValue
            }
        }

        public init() {}
    }

#endif
