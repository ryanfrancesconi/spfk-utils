// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if os(macOS)

    import AppKit
    import Foundation

    /// Thin wrapper ontop of SFSymbol name definitions for simple use in menus
    /// or images.
    ///
    /// SPFKSymbol.plusDiamond.tinted(color: .lightGray)
    /// SPFKSymbol.plusDiamond.tinted(color: .white)
    ///
    public enum SPFKSymbol: String, CaseIterable, Sendable, Codable, Hashable {
        case audioUnit = "dot.radiowaves.left.and.right"
        case bookmark
        case cCircle = "c.circle"
        case cCircleFill = "c.circle.fill"
        case center = "inset.filled.center.rectangle"
        case checkmark
        case chevronDown = "chevron.down"
        case chevronLeft = "chevron.left"
        case chevronRight = "chevron.right"
        case chevronUp = "chevron.up"
        case clock
        case copy = "document.on.document"
        case cut = "scissors"
        case dragAndDrop = "pointer.arrow.and.square.on.square.dashed"
        case dragHandle = "line.3.horizontal"
        case duplicate = "plus.square.on.square"
        case ellipsis
        case eraser
        case eraserLineDashed = "eraser.line.dashed"
        case export = "square.and.arrow.up"
        case exportMultiple = "square.and.arrow.up.on.square"
        case eye
        case eyeSlash = "eye.slash"
        case fill = "inset.filled.rectangle"
        case find = "text.page.badge.magnifyingglass"
        case finder
        case folder
        case folderGearBadge = "folder.badge.gearshape"
        case forward
        case forwardFill = "forward.fill"
        case gearshape
        case hammer
        case headphones
        case hide = "rectangle.dashed"
        case hideOthers = "rectangle.on.rectangle.dashed"
        case horizontalPanelMaximize = "square.bottomhalf.filled"
        case horizontalPanelMinimize = "square.tophalf.filled"
        case infoBubble = "info.bubble"
        case infoCircle = "info.circle"
        case infoTriangle = "info.triangle"
        case lock
        case lockSquareStack = "lock.square.stack"
        case loop = "repeat"
        case macwindow
        case magnifyingGlass = "magnifyingglass"
        case minus
        case minusDiamond = "minus.diamond"
        case musicNote = "music.note"
        case musicNoteSlash = "music.note.slash"
        case musicPages = "music.pages"
        case openDocument = "arrow.up.forward.square"
        case paste = "document.on.clipboard"
        case pause = "stop.fill"
        case performMiniaturize = "minus.rectangle"
        case performZoom = "square.arrowtriangle.4.outward"
        case person
        case piano = "pianokeys.inverse"
        case play
        case playFill = "play.fill"
        case playlist = "music.note.list"
        case playSquareStack = "play.square.stack"
        case plus
        case plusDiamond = "plus.diamond"
        case power
        case quarterNote = "music.quarternote.3"
        case quit = "xmark.rectangle"
        case redo = "arrow.uturn.forward"
        case revert = "arrow.counterclockwise"
        case rewind = "backward"
        case rewindAll = "backward.end"
        case rewindAllFill = "backward.end.fill"
        case rewindFill = "backward.fill"
        case save = "square.and.arrow.down"
        case saveMultiple = "square.and.arrow.down.on.square"
        case searchSparkle = "sparkle.magnifyingglass"
        case selectAll = "character.textbox"
        case selectNext = "arrowtriangle.down.fill"
        case selectPrevious = "arrowtriangle.up.fill"
        case settings = "gear"
        case shield
        case showAll = "rectangle.on.rectangle"
        case sliderHorizontal = "slider.horizontal.3"
        case sliderVertical = "slider.vertical.3"
        case sort = "arrow.up.arrow.down"
        case speakerWave3 = "speaker.wave.3"
        case stopwatch
        case squareStack = "square.stack.3d.up"
        case tablecells
        case tablecellsFill = "tablecells.fill"
        case tag
        case tagFill = "tag.fill"
        case tagSlash = "tag.slash"
        case tagSlashFill = "tag.slash.fill"
        case textSparkle = "character.textbox.badge.sparkles"
        case toggleFullScreen = "arrow.up.left.and.arrow.down.right"
        case trash
        case triangle
        case undo = "arrow.uturn.backward"
        case warning = "exclamationmark.triangle"
        case warningCircle = "exclamationmark.circle"
        case warningCircleFill = "exclamationmark.circle.fill"
        case warningFill = "exclamationmark.triangle.fill"
        case waveform = "waveform.path"
        case waveformSimple = "waveform.path.ecg"
        case waveformMagnifyingGlass = "waveform.path.ecg.magnifyingglass"
        case waveformRectangle = "waveform.path.ecg.rectangle"
        case xmark

        public var systemSymbolName: String { rawValue }

        public var nsImage: NSImage? {
            NSImage(
                systemSymbolName: rawValue,
                accessibilityDescription: rawValue
            )
        }

        public func tinted(color: NSColor) -> NSImage? {
            NSImage.systemSymbol(named: rawValue, tinted: color)
        }
    }

    extension NSImage {
        public static func systemSymbol(named systemSymbolName: String, tinted color: NSColor) -> NSImage? {
            let nsImage = NSImage(
                systemSymbolName: systemSymbolName,
                accessibilityDescription: systemSymbolName
            )

            let config = NSImage.SymbolConfiguration(paletteColors: [color])

            return nsImage?.withSymbolConfiguration(config)
        }
    }

#endif
