// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation
import SPFKBase

extension SPFKSymbol {
    /// The name to request from the system: `rawValue`, or `legacySymbolName` when the running
    /// OS predates it.
    public var systemSymbolName: String {
        guard !isRawValueAvailable, let legacySymbolName else { return rawValue }
        return legacySymbolName
    }

    /// The nearest name available at this package's macOS 13 floor, for a `rawValue` SF Symbols
    /// introduced later. Nil when `rawValue` has always existed.
    ///
    /// `NSImage(systemSymbolName:)` returns nil for a name the running system does not know, and
    /// every call site treats a nil image as no image - so an ungated newer name is a blank
    /// control, not an error. Entries marked *renamed* are the same glyph under its former
    /// spelling; the rest are substitutes.
    public var legacySymbolName: String? {
        switch self {
        // macOS 14.0
        case .gaugeNeedle0, .gaugeNeedle33: "gauge.low"
        case .gaugeNeedle50: "gauge.medium"
        case .gaugeNeedle67, .gaugeNeedle100: "gauge.high"
        case .movieclapper: "film"
        case .performZoom: "arrow.up.left.and.arrow.down.right"
        case .rectanglePortraitRotate: "rectangle.2.swap"
        case .speakerWaveBubble: "speaker.wave.2"
        case .waveformMagnifyingGlass: "waveform.and.magnifyingglass"

        // macOS 15.0, renamed
        case .arrowDownDocument: "arrow.down.doc"
        case .center: "rectangle.center.inset.filled"
        case .clockArrows: "clock.arrow.2.circlepath"
        case .document: "doc"
        case .documentBadgePlus: "doc.badge.plus"
        case .documentOnDocument: "doc.on.doc"
        case .documentOnDocumentFill: "doc.on.doc.fill"
        case .fill: "rectangle.inset.filled"
        case .horizontalPanelMaximized: "rectangle.topthird.inset.filled"
        case .horizontalPanelMinimized: "rectangle.bottomthird.inset.filled"
        case .numbers: "textformat.123"
        case .paste: "doc.on.clipboard"
        case .sliderHorizontalReset: "arrow.counterclockwise.circle"
        case .textDocumentMagnifyingGlass: "doc.text.magnifyingglass"
        case .textFormatCharacters: "textformat"
        case .wandAndSparkles: "wand.and.stars"

        // macOS 15.0, 15.1, 15.2, 15.4
        case .hideOthers: "square.on.square.dashed"
        case .longTextPageAndPencil: "pencil.circle"
        case .waveformBadgeCheckmark: "waveform.badge.plus"
        case .infoTriangle: "exclamationmark.triangle"
        case .textSparkle: "sparkles"

        // macOS 26.0
        case .dragAndDrop: "cursorarrow.and.square.on.square.dashed" // renamed
        case .finder: "folder"
        case .minusPlusLines: "ruler"
        case .musicNoteSlash: "waveform.slash"
        case .musicNoteSquareStack, .musicPages: "music.note.list"
        case .interfaceWindowOnRectangle: "macwindow.on.rectangle"
        case .listBulletBadgeEllipsis: "list.bullet"
        case .waveformMid: "waveform"

        default: nil
        }
    }

    /// Whether the running OS knows `rawValue`. Every case here has a `legacySymbolName`.
    private var isRawValueAvailable: Bool {
        switch self {
        case .gaugeNeedle0, .gaugeNeedle33, .gaugeNeedle50, .gaugeNeedle67, .gaugeNeedle100,
             .movieclapper, .performZoom, .rectanglePortraitRotate, .speakerWaveBubble, .waveformMagnifyingGlass:
            OSVersion.macOS14.isAvailable

        case .arrowDownDocument, .center, .clockArrows, .document, .documentBadgePlus, .documentOnDocument,
             .documentOnDocumentFill, .fill, .hideOthers, .horizontalPanelMaximized,
             .horizontalPanelMinimized, .numbers, .paste, .sliderHorizontalReset, .textDocumentMagnifyingGlass,
             .textFormatCharacters, .wandAndSparkles:
            OSVersion.macOS15.isAvailable

        case .waveformBadgeCheckmark: OSVersion.macOS15_1.isAvailable
        case .infoTriangle: OSVersion.macOS15_2.isAvailable
        case .longTextPageAndPencil, .textSparkle: OSVersion.macOS15_4.isAvailable

        case .dragAndDrop, .finder, .interfaceWindowOnRectangle, .listBulletBadgeEllipsis, .minusPlusLines, .musicNoteSlash,
             .musicNoteSquareStack, .musicPages, .waveformMid:
            OSVersion.macOS26.isAvailable

        default: true
        }
    }
}
