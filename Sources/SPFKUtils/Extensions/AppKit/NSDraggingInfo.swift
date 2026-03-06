// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import SPFKBase

    extension NSDraggingInfo {
        @MainActor
        public func toURL() throws -> [URL] {
            guard let items = draggingPasteboard.pasteboardItems,
                  items.isNotEmpty,
                  let types = draggingPasteboard.types
            else {
                throw NSError(description: "pasteboardItems is empty")
            }

            var urls = [URL]()

            for item in items {
                guard let type = item.availableType(from: types) else {
                    Log.error("Failed to determine availableType for", item)
                    continue
                }

                guard type == .fileURL else {
                    Log.error("type must be .fieURL but is \(type)")
                    continue
                }

                guard let url = convertToURL(item: item) else {
                    Log.error("Failed to parse URL from \(type)")
                    continue
                }

                urls.append(url)
            }

            guard urls.isNotEmpty else {
                throw NSError(description: "No files were found")
            }

            return urls
        }

        private func convertToURL(item: NSPasteboardItem) -> URL? {
            guard let stringValue = item.string(forType: .fileURL) else {
                Log.error("failed to convert URL item to string")
                return nil
            }

            guard let url = URL(string: stringValue), url.exists else {
                return nil
            }

            return url
        }

        @MainActor
        public func toString() throws -> [String] {
            guard let items = draggingPasteboard.pasteboardItems,
                  items.isNotEmpty,
                  let types = draggingPasteboard.types
            else {
                throw NSError(description: "pasteboardItems is empty")
            }

            guard types.contains(.string) else {
                throw NSError(description: "no .string type in types")
            }

            var results: [String] = []

            for item in items {
                guard let stringValue = item.data(forType: .string) else {
                    Log.error("failed to convert to string")
                    continue
                }

                if let string = stringValue.toString(using: .utf8) {
                    results.append(string)
                }
            }

            return results
        }
    }

#endif
