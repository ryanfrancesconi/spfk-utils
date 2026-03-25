// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import AppKit
    import Foundation
    import SPFKBase

    // swiftformat:disable consecutiveSpaces

    public enum SPFKColor {
        case controlAccentColor
        case controlActiveBackgroundColor
        case controlAlphaBackgroundColor
        case controlBackgroundColor
        case controlDarkBackgroundColor
        case defaultWaveformColor
        case gridBackgroundColor
        case gridColor
        case secondaryLabelColor
        case selectedTextColor
        case textColor
        case schemeColor
        case schemeColorAlternate

        public func value(for scheme: SPFKColorScheme) -> NSColor {
            switch self {
            case .controlAccentColor:           scheme == .dark ? Self.xcPreprocessor : Self.xcPreprocessor
            case .controlActiveBackgroundColor: scheme == .dark ? Self.defaultControlSelected : Self.defaultControlSelected
            case .controlAlphaBackgroundColor:  scheme == .dark ? Self.alphaWhite06 : Self.alphaBlack02
            case .controlBackgroundColor:       scheme == .dark ? #colorLiteral(red: 0.2728477716, green: 0.2728477716, blue: 0.2728477716, alpha: 1) : #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974402547, alpha: 1)
            case .controlDarkBackgroundColor:   scheme == .dark ? #colorLiteral(red: 0.1600990295, green: 0.1600990295, blue: 0.1600990295, alpha: 1) : #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974402547, alpha: 1)
            case .defaultWaveformColor:         scheme == .dark ? Self.xcPreprocessor : Self.xcPreprocessor
            case .gridBackgroundColor:          scheme == .dark ? #colorLiteral(red: 0.1949233711, green: 0.1949233711, blue: 0.1949233711, alpha: 1) : #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974402547, alpha: 1)
            case .gridColor:                    scheme == .dark ? #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974403739, alpha: 1) : #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
            case .secondaryLabelColor:          scheme == .dark ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5490196078) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5490196078)
            case .selectedTextColor:            scheme == .dark ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
            case .textColor:                    scheme == .dark ? #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974403739, alpha: 1) : #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
            case .schemeColor:                  scheme == .dark ? #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974403739, alpha: 1) : #colorLiteral(red: 0.1600990295, green: 0.1600990295, blue: 0.1600990295, alpha: 1)
            case .schemeColorAlternate:         scheme == .dark ? #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) : #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            }
        }

        public func hexColor(for scheme: SPFKColorScheme) -> HexColor? {
            HexColor(nsColor: value(for: scheme))
        }
    }

    // MARK: Dark Mode Code Colors

    extension SPFKColor {
        public static let xcAttribute =     #colorLiteral(red: 0.7238948941, green: 0.5747394562, blue: 0.4295355082, alpha: 1)
        public static let xcCharacter =     #colorLiteral(red: 0.8802540898, green: 0.8195596337, blue: 0.5590798259, alpha: 1)
        public static let xcClass =         #colorLiteral(red: 0.7232261896, green: 0.9541102052, blue: 0.9142815471, alpha: 1)
        public static let xcComments =      #colorLiteral(red: 0.4976361394, green: 0.6253806949, blue: 0.4622306824, alpha: 1)
        public static let xcKeyword =       #colorLiteral(red: 0.8808391094, green: 0.5707122684, blue: 0.6889952421, alpha: 1)
        public static let xcOther =         #colorLiteral(red: 0.4524430037, green: 0.7576714158, blue: 0.7977759242, alpha: 1)
        public static let xcPreprocessor =  #colorLiteral(red: 1, green: 0.6314829588, blue: 0.309850961, alpha: 1)
        public static let xcRegEx =         #colorLiteral(red: 0.9234126806, green: 0.5465388894, blue: 0.4782198668, alpha: 1)
        public static let xcString =        #colorLiteral(red: 0.7784311771, green: 0.5900088549, blue: 0.5077829957, alpha: 1)
        public static let xcType =          #colorLiteral(red: 0.496894896, green: 0.8131126761, blue: 0.9852605462, alpha: 1)
        public static let xcURL =           #colorLiteral(red: 0.4614251852, green: 0.6554939747, blue: 0.9696692824, alpha: 1)
        public static let xcPurple =        #colorLiteral(red: 0.6859937906, green: 0.4683517218, blue: 0.9155258536, alpha: 1)
    }

    // MARK: Some static defaults

    extension SPFKColor {
        public static let alphaWhite06 = NSColor.white.withAlphaComponent(0.06)
        public static let alphaWhite02 = NSColor.white.withAlphaComponent(0.02)

        public static let alphaBlack02 = NSColor.black.withAlphaComponent(0.2)
        public static let alphaYellow = #colorLiteral(red: 0.9686274529, green: 0.7471076061, blue: 0.1296119144, alpha: 1).withAlphaComponent(0.6)

        public static let defaultControlSelected = Self.xcPreprocessor.withAlphaComponent(0.3)
        public static let defaultControlUnselected = alphaWhite06
        public static let defaultControlStrokeSelected = SPFKColor.controlActiveBackgroundColor.value(for: .dark)
        public static let defaultControlStrokeUnselected = SPFKColor.textColor.value(for: .dark)

        public static let xcHexColors: [HexColor] = [
            xcAttribute, xcCharacter, xcClass, xcComments, xcKeyword,
            xcOther, xcPreprocessor, xcRegEx, xcString, xcType, xcURL,
            xcPurple
        ].compactMap {
            HexColor(nsColor: $0)
        }
    }

    // swiftformat:enable consecutiveSpaces

#endif
