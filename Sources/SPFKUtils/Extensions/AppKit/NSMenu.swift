// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSMenu {
        /// Removes checked state from all items.
        public func checkNone() {
            for item in items {
                item.state = .off
            }
        }

        public func copyItems(to target: NSMenu) {
            for item in items {
                if let mitem = item.copy() as? NSMenuItem {
                    target.addItem(mitem)
                }
            }
        }

        /// Recursively enable menu items by their tag values.
        /// Calling this function will set `autoenablesItems` = false
        ///
        /// - Parameters:
        ///   - menu: nil = self
        ///   - tags: Array of [Int] tags or nil to change all items found
        ///   - enabled: new state
        public func updateItems(in menu: NSMenu? = nil, tags: [Int]? = nil, enabled: Bool) {
            let menu = menu ?? self

            menu.autoenablesItems = false

            for item in menu.items {
                if let tags {
                    if tags.contains(item.tag) {
                        item.isEnabled = enabled
                    }

                } else {
                    item.isEnabled = enabled
                }

                if let submenu = item.submenu, submenu.items.isNotEmpty {
                    updateItems(in: submenu, tags: tags, enabled: enabled)
                }
            }
        }
    }
#endif
