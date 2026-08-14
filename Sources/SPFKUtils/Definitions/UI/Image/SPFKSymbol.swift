// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// Thin convenience enum wrapper ontop of SFSymbol name definitions for simple use in menus
/// or images.
///
/// SPFKSymbol.arrowClockwise.tinted(color: .lightGray)
/// SPFKSymbol.arrowClockwise.tinted()
///
public enum SPFKSymbol: String, CaseIterable, Sendable, Codable, Hashable {
    
    case arrowClockwise = "arrow.clockwise"
    case arrowDownCircle = "arrow.down.circle"
    case arrowRightArrowLeft = "arrow.right.arrow.left"
    case arrowLeftAndRight = "arrow.left.and.right"
    case arrowLeftAndRightSquare = "arrow.left.and.right.square"
    case arrowUpArrowDown = "arrow.up.backward.and.arrow.down.forward"
    case arrowTurnDownLeft = "arrow.turn.down.left"
    case arrowsCross = "arrow.up.and.down.and.arrow.left.and.right"
    case arrowTrianglesRightAndLeft = "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left"
    case arrowUpToLine = "arrow.up.to.line"
    case audioUnit = "dot.radiowaves.left.and.right"
    case barcode
    case bell
    case bookmark
    case bookmarkSlash = "bookmark.slash"
    case bubbleLeft = "bubble.left"
    case calendar
    case cart
    case cCircle = "c.circle"
    case cCircleFill = "c.circle.fill"
    case checklist
    case circleSlash = "circle.slash"
    case center = "inset.filled.center.rectangle"
    case checkmark
    case checkmarkCircle = "checkmark.circle"
    case chevronDown = "chevron.down"
    case chevronLeft = "chevron.left"
    case chevronMarkup = "chevron.left.forwardslash.chevron.right"
    case chevronRight = "chevron.right"
    case chevronUp = "chevron.up"
    case circle
    case circleFill = "circle.fill"
    case circleBadgeFill = "circlebadge.fill"
    case clock
    case clockArrowCirclepath = "clock.arrow.circlepath"
    case clockArrows = "clock.arrow.trianglehead.2.counterclockwise.rotate.90"
    case documentOnDocument = "document.on.document"
    case documentOnDocumentFill = "document.on.document.fill"
    case crop
    case dialHigh = "dial.high"
    case diamond
    case document
    case documentBadgePlus = "document.badge.plus"
    case dragAndDrop = "pointer.arrow.and.square.on.square.dashed"
    case dragHandle = "line.3.horizontal"
    case duplicate = "plus.square.on.square"
    case ellipsis
    case ellipsisCircle = "ellipsis.circle"
    case eraser
    case eraserLineDashed = "eraser.line.dashed"
    case escape
    case export = "square.and.arrow.up"
    case exportMultiple = "square.and.arrow.up.on.square"
    case eye
    case eyeSlash = "eye.slash"
    case fill = "inset.filled.rectangle"
    case film
    case filmStack = "film.stack"
    case finder
    case flag
    case folder
    case folderBadgePlus = "folder.badge.plus"
    case folderGearBadge = "folder.badge.gearshape"
    case forward
    case forwardAll = "forward.end"
    case forwardAllFill = "forward.end.fill"
    case forwardFill = "forward.fill"
    case gauge = "gauge.medium"
    /// Needle positions, for showing a rate on a dial rather than only naming it.
    case gaugeNeedle0 = "gauge.with.dots.needle.0percent"
    case gaugeNeedle33 = "gauge.with.dots.needle.33percent"
    case gaugeNeedle50 = "gauge.with.dots.needle.50percent"
    case gaugeNeedle67 = "gauge.with.dots.needle.67percent"
    case gaugeNeedle100 = "gauge.with.dots.needle.100percent"
    case gearshape
    case hammer
    case handWave = "hand.wave"
    case headphones
    case hide = "rectangle.dashed"
    case hideOthers = "rectangle.on.rectangle.dashed"
    case horizontalPanelMaximized = "inset.filled.topthird.rectangle"
    case horizontalPanelMinimized = "inset.filled.bottomthird.rectangle"
    case infoBubble = "info.bubble"
    case `import` = "tray.and.arrow.down"
    case infoCircle = "info.circle"
    case infoTriangle = "info.triangle"
    case linesDecrease = "line​.3​.horizontal​.decrease"
    case listAndFilm = "list.and.film"
    case listBullet = "list.bullet"
    case lock
    case lockSquareStack = "lock.square.stack"
    case loop = "repeat"
    case macwindow
    case magnifyingGlass = "magnifyingglass"
    case mapPin = "mappin.and.ellipse"
    case mathFunction = "function"
    case metronome
    case metronomeFill = "metronome.fill"
    case minus
    case minusDiamond = "minus.diamond"
    case minusPlusLines = "minus.plus.lines.measurement.horizontal.aligned.bottom"
    case mountain = "mountain.2"
    case movieclapper
    case musicNote = "music.note"
    case musicNoteSlash = "music.note.slash"
    case musicPages = "music.pages"
    case nosign
    case numbers
    case openDocument = "arrow.up.forward.square"
    case paintpalette
    case paintPaletteFill = "paintpalette.fill"
    case paste = "document.on.clipboard"
    case pause = "stop.fill"
    case performMiniaturize = "minus.rectangle"
    case performZoom = "square.arrowtriangle.4.outward"
    case person
    case photo
    case photoStack = "photo.stack"
    case piano = "pianokeys.inverse"
    case play
    case playSlash = "play.slash"
    case pencil
    case pencilCircle = "pencil.circle"
    case squareAndPencil = "square.and.pencil"
    case pipExit = "pip.exit"
    case pipEnter = "pip.enter"
    case playFill = "play.fill"
    case playlist = "music.note.list"
    case playSquareStack = "play.square.stack"
    case plus
    case plusDiamond = "plus.diamond"
    case plusSquare = "plus.square"
    case power
    case quarterNote = "music.quarternote.3"
    case questionmarkCircle = "questionmark.circle"
    case quit = "xmark.rectangle"
    case rectanglePortraitArrowTriangle = "rectangle.portrait.arrowtriangle.2.inward"
    case redo = "arrow.uturn.forward"
    case returnKey = "return"
    case revert = "arrow.counterclockwise"
    case rewind = "backward"
    case rewindAll = "backward.end"
    case rewindAllFill = "backward.end.fill"
    case rewindFill = "backward.fill"
    case ruler
    case save = "square.and.arrow.down"
    case saveFill = "square.and.arrow.down.fill"
    case saveMultiple = "square.and.arrow.down.on.square"
    case scissors
    case scissorsBadgeEllipsis = "scissors.badge.ellipsis"
    case selectAll = "character.textbox"
    case selectNext = "arrowtriangle.down.fill"
    case selectPrevious = "arrowtriangle.up.fill"
    case settings = "gear"
    case shield
    case showAll = "rectangle.on.rectangle"
    case shippingbox
    case shippingboxAndArrow = "shippingbox.and.arrow.backward"
    case shuffle
    case sidebarLeading = "sidebar.leading"
    case sidebarTrailing = "sidebar.trailing"
    case sliderHorizontal = "slider.horizontal.3"
    case sliderVertical = "slider.vertical.3"
    case sort = "arrow.up.arrow.down"
    case sparkleMagnifyingGlass = "sparkle.magnifyingglass"
    /// The volume ladder, for showing a level rather than only naming it.
    case speaker
    case speakerSlash = "speaker.slash"
    case speakerWave1 = "speaker.wave.1"
    case speakerWave2 = "speaker.wave.2"
    case speakerWave3 = "speaker.wave.3"
    case speakerFill = "speaker.fill"
    case speakerSlashFill = "speaker.slash.fill"
    case speakerWave1Fill = "speaker.wave.1.fill"
    case speakerWave2Fill = "speaker.wave.2.fill"
    case speakerWave3Fill = "speaker.wave.3.fill"
    case speakerWaveBubble = "speaker.wave.2.bubble"
    case squareStack = "square.stack"
    case squareStack3d = "square.stack.3d.up"
    case star
    case starFill = "star.fill"
    case stopwatch
    case tablecells
    case tablecellsFill = "tablecells.fill"
    case tablecellBadgeEllipse = "tablecells.badge.ellipsis"
    case tag
    case tagFill = "tag.fill"
    case tagSlash = "tag.slash"
    case tagSlashFill = "tag.slash.fill"
    case textAlignLeft = "text.alignleft"
    case textAlignRight = "text.alignright"
    case textBadgePlus = "text.badge.plus"
    case textDocumentMagnifyingGlass = "text.page.badge.magnifyingglass"
    case textMagnifyingGlass = "text.magnifyingglass"
    case textSparkle = "character.textbox.badge.sparkles"
    case toggleFullScreen = "arrow.up.left.and.arrow.down.right"

    /// The counterpart to ``toggleFullScreen`` -- arrows pointing inward, for a control shown
    /// while full screen is already up.
    case exitFullScreen = "arrow.down.right.and.arrow.up.left"

    case trash
    case triangle
    case triangleFill = "triangle.fill"
    case triangleLeftHalfFilled = "triangle.lefthalf.filled"
    case triangleRightHalfFilled = "triangle.righthalf.filled"
    case tuningfork
    case uiwindow = "uiwindow.split.2x1"
    case undo = "arrow.uturn.backward"
    case wandAndSparkles = "wand.and.sparkles"
    case warning = "exclamationmark.triangle"
    case warningCircle = "exclamationmark.circle"
    case warningCircleFill = "exclamationmark.circle.fill"
    case warningFill = "exclamationmark.triangle.fill"
    case waveform = "waveform.path"
    case waveformMid = "waveform.mid"
    case waveformBadgePlus = "waveform.badge.plus"
    case waveformBadgeCheckmark = "waveform.badge.checkmark"
    case waveformCircle = "waveform.circle"
    case waveformMagnifyingGlass = "waveform.badge.magnifyingglass"
    case waveformRectangle = "waveform.path.ecg.rectangle"
    case waveformSimple = "waveform.path.ecg"
    case waveformSlash = "waveform.slash"
    case wrenchAndScrewdriver = "wrench.and.screwdriver"
    case xmark
    case xCircle = "x.circle"
    case xCircleFill = "x.circle.fill"

    public var systemSymbolName: String { rawValue }
}

#if os(macOS)
    import AppKit

    extension SPFKSymbol: NSImageConvertible {
        // NSImageConvertible
        public var nsImage: NSImage? {
            NSImage(
                systemSymbolName: systemSymbolName,
                accessibilityDescription: systemSymbolName
            )
        }

        // override default impl
        public func tinted(color: NSColor) -> NSImage? {
            NSImage.systemSymbol(
                named: rawValue,
                tinted: color
            )
        }

        @MainActor
        public func tinted(currentScheme: SPFKColorScheme = .currentScheme) -> NSImage? {
            let appearanceName: NSAppearance.Name = currentScheme == .dark ? .darkAqua : .aqua
            let appearance = NSAppearance(named: appearanceName) ?? NSAppearance.currentDrawing()
            var color: NSColor = SPFKSchemeColor.primary.nsColor

            appearance.performAsCurrentDrawingAppearance {
                if let resolved = NSColor(cgColor: SPFKSchemeColor.primary.cgColor) {
                    color = resolved
                }
            }
            return tinted(color: color)
        }
    }

#endif
