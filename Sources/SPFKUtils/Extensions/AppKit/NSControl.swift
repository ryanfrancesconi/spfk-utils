// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
    import AppKit

    extension NSControl {
        @MainActor
        public func popUpContextMenuBeneath(
            _ menu: NSMenu,
            with event: NSEvent?
        ) {
            let offset: CGFloat = isFlipped ? 5 : -5

            let localLocation = NSPoint(x: 0, y: frame.height + offset)
            let windowLocation = convert(localLocation, to: nil)

            guard let newEvent = NSEvent.mouseEvent(
                with: event?.type ?? .leftMouseDown,
                location: windowLocation,
                modifierFlags: event?.modifierFlags ?? [],
                timestamp: event?.timestamp ?? 0,
                windowNumber: event?.windowNumber ?? window?.windowNumber ?? 0,
                context: nil,
                eventNumber: event?.eventNumber ?? NSApp.currentEvent?.eventNumber ?? 0,
                clickCount: event?.clickCount ?? 1,
                pressure: 0
            ) else {
                return
            }

            NSMenu.popUpContextMenu(
                menu,
                with: newEvent,
                for: self
            )
        }
    }
#endif
