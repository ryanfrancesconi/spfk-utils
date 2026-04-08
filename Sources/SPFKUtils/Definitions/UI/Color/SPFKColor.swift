// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils
// swiftformat:disable consecutiveSpaces

#if os(macOS)

    import AppKit
    import Foundation
    import SPFKBase

    public enum SPFKColor {
        case clear
        case windowBackgroundColor

        case controlAccentColor
        case controlActiveBackgroundColor
        case controlAlphaBackgroundColor
        case controlBackgroundColor
        case controlDarkBackgroundColor
        case defaultWaveformColor
        case gridBackgroundColor
        case gridColor

        case labelColor
        case secondaryLabelColor
        case tertiaryLabelColor
        case selectedLabelColor
        case disabledLabelColor
        case headerLabelColor

        case schemeColor
        case schemeColorAlternate

        /// Dynamic NSColor that auto-resolves based on the current appearance context.
        /// When assigning to a CALayer property (which requires CGColor), use `.cgColor`
        /// and re-call inside `viewDidChangeEffectiveAppearance()` to update the layer.
        public var nsColor: NSColor {
            NSColor(name: nil) { [self] appearance in
                let name = appearance.bestMatch(from: [.aqua, .darkAqua]) ?? .darkAqua
                return name == .aqua ? lightColor : darkColor
            }
        }

        /// Resolved CGColor for the current appearance context.
        /// Re-call inside `viewDidChangeEffectiveAppearance()` to pick up the new scheme.
        public var cgColor: CGColor { nsColor.cgColor }

        /// Convenience for HexColor conversion using the current appearance context.
        public var hexColor: HexColor? { HexColor(nsColor: nsColor) }

        // MARK: - Dark values

        private var darkColor: NSColor {
            switch self {
            case .clear:                        .clear
            case .windowBackgroundColor:        .windowBackgroundColor
            case .controlAccentColor:           Self.xcPreprocessor
            case .controlActiveBackgroundColor: Self.xcPreprocessor.withAlphaComponent(0.3)
            case .controlAlphaBackgroundColor:  .white.withAlphaComponent(0.06)
            case .controlBackgroundColor:       #colorLiteral(red: 0.2728477716, green: 0.2728477716, blue: 0.2728477716, alpha: 1)
            case .controlDarkBackgroundColor:   #colorLiteral(red: 0.1600990295, green: 0.1600990295, blue: 0.1600990295, alpha: 1)
            case .defaultWaveformColor:         Self.xcPreprocessor
            case .gridBackgroundColor:          #colorLiteral(red: 0.1949233711, green: 0.1949233711, blue: 0.1949233711, alpha: 1)
            case .gridColor:                    #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974403739, alpha: 1)
            case .labelColor:                   .labelColor
            case .secondaryLabelColor:          .secondaryLabelColor
            case .tertiaryLabelColor:           .tertiaryLabelColor
            case .selectedLabelColor:           #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            case .disabledLabelColor:            .disabledControlTextColor
            case .headerLabelColor:             .labelColor.withAlphaComponent(0.75)
            case .schemeColor:                  #colorLiteral(red: 0.8974402547, green: 0.8974402547, blue: 0.8974403739, alpha: 1)
            case .schemeColorAlternate:         #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        }

        // MARK: - Light values

        private var lightColor: NSColor {
            switch self {
            case .clear:                        .clear
            case .windowBackgroundColor:        .windowBackgroundColor
            case .controlAccentColor:           Self.xcPreprocessor
            case .controlActiveBackgroundColor: Self.xcPreprocessor.withAlphaComponent(0.6)
            case .controlAlphaBackgroundColor:  .black.withAlphaComponent(0.06)
            case .controlBackgroundColor:       #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.6)
            case .controlDarkBackgroundColor:   .black.withAlphaComponent(0.06)
            case .defaultWaveformColor:         Self.fcpMusic2
            case .gridBackgroundColor:          #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            case .gridColor:                    #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
            case .labelColor:                   .labelColor
            case .secondaryLabelColor:          .secondaryLabelColor
            case .tertiaryLabelColor:           .tertiaryLabelColor
            case .selectedLabelColor:           #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
            case .disabledLabelColor:            .disabledControlTextColor
            case .headerLabelColor:             .labelColor.withAlphaComponent(0.75)
            case .schemeColor:                  #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
            case .schemeColorAlternate:         #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            }
        }
    }

    // MARK: Dark Mode Code Colors

    extension SPFKColor {
        // MARK: Xcode Dark Mode

        public static let xcPreprocessor =      #colorLiteral(red: 1, green: 0.6314829588, blue: 0.309850961, alpha: 1)
        public static let xcRegEx =             #colorLiteral(red: 0.9234126806, green: 0.5465388894, blue: 0.4782198668, alpha: 1)
        public static let xcKeyword =           #colorLiteral(red: 0.8808391094, green: 0.5707122684, blue: 0.6889952421, alpha: 1)
        public static let xcString =            #colorLiteral(red: 0.7784311771, green: 0.5900088549, blue: 0.5077829957, alpha: 1)
        public static let xcAttribute =         #colorLiteral(red: 0.7238948941, green: 0.5747394562, blue: 0.4295355082, alpha: 1)
        public static let xcCharacter =         #colorLiteral(red: 0.8802540898, green: 0.8195596337, blue: 0.5590798259, alpha: 1)
        public static let xcClass =             #colorLiteral(red: 0.7232261896, green: 0.9541102052, blue: 0.9142815471, alpha: 1)
        public static let xcComments =          #colorLiteral(red: 0.4976361394, green: 0.6253806949, blue: 0.4622306824, alpha: 1)
        public static let xcType =              #colorLiteral(red: 0.496894896, green: 0.8131126761, blue: 0.9852605462, alpha: 1)
        public static let xcOther =             #colorLiteral(red: 0.4524430037, green: 0.7576714158, blue: 0.7977759242, alpha: 1)
        public static let xcURL =               #colorLiteral(red: 0.4614251852, green: 0.6554939747, blue: 0.9696692824, alpha: 1)
        public static let xcPurple =            #colorLiteral(red: 0.6859937906, green: 0.4683517218, blue: 0.9155258536, alpha: 1)
    }

    extension SPFKColor {
        // MARK: Final Cut Pro Role Colors

        public static let fcpFootsteps =        #colorLiteral(red: 0.3490821421, green: 0.1138016656, blue: 0.192650944, alpha: 1)
        public static let fcpMusic2 =           #colorLiteral(red: 0.5345640779, green: 0.2465824187, blue: 0.08071980625, alpha: 1)
        public static let fcpSoundDesign =      #colorLiteral(red: 0.5058107972, green: 0.3126704097, blue: 0.08611684293, alpha: 1)
        public static let fcpAdjustmentClips1 = #colorLiteral(red: 0.5058107972, green: 0.3126704097, blue: 0.08611684293, alpha: 1)
        public static let fcpAdjustmentClips2 = #colorLiteral(red: 0.683828339, green: 0.4227131728, blue: 0.1164252285, alpha: 1)
        public static let fcpFoley1 =           #colorLiteral(red: 0.3768741899, green: 0.5601573603, blue: 0.1064454123, alpha: 1)
        public static let fcpFoley2 =           #colorLiteral(red: 0.2555211484, green: 0.3797873557, blue: 0.07217011601, alpha: 1)
        public static let fcpMusic1 =           #colorLiteral(red: 0.07852575928, green: 0.3265568018, blue: 0.1685996056, alpha: 1)
        public static let fcpEffects =          #colorLiteral(red: 0.09073310345, green: 0.342267096, blue: 0.361043334, alpha: 1)
        public static let fcpVocalizations =    #colorLiteral(red: 0.09079078585, green: 0.3421320617, blue: 0.2794510722, alpha: 1)
        public static let fcpDialogue =         #colorLiteral(red: 0.1128803566, green: 0.2022444606, blue: 0.3314594924, alpha: 1)
        public static let fcpTitles =           #colorLiteral(red: 0.3136634827, green: 0.2073241472, blue: 0.5196961164, alpha: 1)
    }

    // MARK: Static defaults

    extension SPFKColor {
        public static let alphaWhite06 = NSColor.white.withAlphaComponent(0.06)
        public static let alphaWhite02 = NSColor.white.withAlphaComponent(0.02)
        public static let alphaBlack06 = NSColor.black.withAlphaComponent(0.06)
        public static let alphaBlack20 = NSColor.black.withAlphaComponent(0.2)

        public static let yellowWarning = #colorLiteral(red: 0.9686274529, green: 0.7471076061, blue: 0.1296119144, alpha: 1).withAlphaComponent(0.8)
        public static let darkYellowWarning = #colorLiteral(red: 0.8179681825, green: 0.6191367307, blue: 0.06488587422, alpha: 1).withAlphaComponent(0.6)
        public static let redError = NSColor(red: 0.75, green: 0.25, blue: 0.15, alpha: 1)

        /// Dynamic: selected control fill color. Re-resolves per appearance context.
        public static var defaultControlSelected: NSColor {
            SPFKColor.controlActiveBackgroundColor.nsColor
        }

        /// Dynamic: unselected control fill color. Re-resolves per appearance context.
        public static var defaultControlUnselected: NSColor {
            SPFKColor.controlAlphaBackgroundColor.nsColor
        }

        /// Dynamic: selected control stroke color. Re-resolves per appearance context.
        public static var defaultControlStrokeSelected: NSColor {
            SPFKColor.controlActiveBackgroundColor.nsColor
        }

        /// Dynamic: unselected control stroke color. Re-resolves per appearance context.
        public static var defaultControlStrokeUnselected: NSColor {
            SPFKColor.labelColor.nsColor
        }

        public static let customSwatchColors: [HexColor] = [
            xcPreprocessor,
            xcRegEx,
            xcKeyword,
            xcString,
            xcAttribute,
            xcCharacter,
            xcClass,
            xcComments,
            xcType,
            xcOther,
            xcURL,
            xcPurple,
            //
            fcpFootsteps,
            fcpMusic2,
            fcpSoundDesign,
            fcpAdjustmentClips1,
            fcpAdjustmentClips2,
            fcpFoley1,
            fcpFoley2,
            fcpMusic1,
            fcpEffects,
            fcpVocalizations,
            fcpDialogue,
            fcpTitles
        ].compactMap {
            HexColor(nsColor: $0)
        }

        public static func random() -> HexColor? {
            customSwatchColors.randomElement()
        }
    }

#endif
// swiftformat:enable consecutiveSpaces
