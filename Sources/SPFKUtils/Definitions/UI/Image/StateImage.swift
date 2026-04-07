// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)
import AppKit

public struct StateImage {
    public var image: NSImage?
    public var alternateImage: NSImage?
    
    public var hasImage: Bool {
        image != nil || alternateImage != nil
    }

    public subscript(key: NSControl.StateValue) -> NSImage? {
        get {
            key == .on ? alternateImage : image
        }

        set {
            switch key {
            case .on:
                alternateImage = newValue

            case .off:
                image = newValue

            default:
                image = newValue
            }
        }
    }

    public init(image: NSImage? = nil, alternateImage: NSImage? = nil) {
        self.image = image
        self.alternateImage = alternateImage
    }
}
#endif
