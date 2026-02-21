// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    import AppKit
    import Combine

    public class AppearanceObserver: NSObject {
        public enum Event {
            case appearanceChanged(NSAppearance)
        }

        public var eventHandler: ((Event) -> Void)?

        private var cancellables = Set<AnyCancellable>()

        override public init() {
            super.init()
        }

        @MainActor public func addObserver() {
            guard cancellables.isEmpty else { return }

            NSApp.publisher(for: \.effectiveAppearance)
                .sink { [weak self] newAppearance in
                    self?.eventHandler?(.appearanceChanged(newAppearance))
                }
                .store(in: &cancellables)
        }

        public func removeObserver() {
            guard cancellables.isNotEmpty else { return }

            for cancellable in cancellables {
                cancellable.cancel()
            }
        }
    }

#endif
