# SPFKUtils
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-utils)](https://github.com/ryanfrancesconi/spfk-utils/tags)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-utils%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-utils)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-utils%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-utils)

A Swift utility library providing UI definitions, audio extensions, and Foundation/CoreGraphics conveniences for macOS and iOS development.

## Requirements

- **Platforms:** macOS 13+, iOS 16+
- **Swift:** 6.2+

## Modules

### Definitions

- **DictionaryParser** — Type-safe accessor wrapper around `[String: Any]` dictionaries with support for strings, numbers, booleans, URLs, and nested structures.
- **Rescale** — Linear interpolation and mapping between numeric domains and ranges.
- **Counter** — Simple incrementing counter with reset support.
- **ProgressTracker / ChunkedProgressTracker** — Track completion progress as a normalized value, with optional chunked progress for parallel operations.
- **URLProperties** — Structured metadata container for URL-associated properties.
- **HardwareInfo** — System hardware queries (model identifier, machine name).
- **ProcessHandler** — Launch and manage external processes with stdout/stderr capture.
- **StereoState** — Enumeration of stereo routing states (stereo, mono, left, right, swapped).
- **ByteCount** — Binary size constants and human-readable file-size formatting.
- **SearchScope** — Whether a search covers everything in scope or only the current selection.
- **DictionaryMergeScheme** — How two dictionaries combine: preserve, replace, or combine.
- **CSVBuilder** — RFC 4180 CSV text from a header row and a per-row value provider.
- **GroupByTagDirectory** — Resolves an output directory by appending subdirectories derived from tag values, splitting on `/` so a value can name a nested path.
- **ProcessHandler** — Launch and manage external processes with stdout/stderr capture.
- **Email** — Composing a mail message.

### Concurrency

- **batchMap** — Bounded-concurrency map over a collection. For CPU-bound work set the batch size near the core count, since a task holds a thread while it runs; for suspending work it is a resource knob rather than a throughput one, because a suspended task holds no thread.

### Caching

- **ImageDataStore / ImageDataStoreAccess / CachedImageType** — A disk cache for decoded images, and the narrow protocol a data layer exposes it through.
- **ShardedDirectory** — A 2-hex-character prefix scheme (256 shards) laid out as `<root>/<key[0..<2]>/<key><suffix>`, so a large library does not pay flat-directory enumeration costs.
- **FlatToShardedMigration** — Moves a legacy flat cache into that layout, owning where the old directory was and how to prune orphans during the migration window. The store itself knows nothing about any prior location.

### Timers

- **BasicTimer / RepeatingTimer / OneShotTimer** — Simple timers behind one `TimerModel` protocol, with `TimerType` and `TimerState`.
- **DisplayLinkTimer / LegacyDisplayLinkTimer** — Screen-refresh-synced timing for playhead and transport updates.

### Outline and table state

- **OutlineNode / OutlineNodeCollection / NodeIdentifier** — The sidebar tree's node model and its stable identifier.
- **OutlineState** — Expansion state, persisted.
- **OutlineEditOperation** — One edit to that tree.
- **NavigationHistory** — Back/forward through sidebar selections.
- **TableColumnState** — One column's title, stable identifier, width and visibility, saved independently of AppKit's autosave. The identifier is always the matching key; old saves predating the title/identifier split fall back to using the title as the identifier.
- **TableColumnPreset / TableSortState / SortValue** — A named column layout, and how a table is sorted.
- **PasteboardCopyable** — What a type does to put itself on the pasteboard.

### UI

- **HexColor / RGBAColor** — Hex string and RGBA representations for cross-platform color handling.
- **SPFKSchemeColor** — The two neutral grays used as default arguments by `SPFKSymbol.tinted()` and `NSImageConvertible.stateImage()`. It stays here rather than moving to `spfk-ui` with the rest of the color layer, because data packages reach it and `spfk-ui` already depends on them — the reverse edge would be a cycle.
- **SPFKSymbol** — SF Symbol definitions with tinting and state images. Here for the same reason.
- **AppearanceObserver** — Observe system appearance (light/dark mode) changes via Combine.
- **StateImage** — Associate images with on/off/disabled control states.
- **FirstResponder** — Utilities for managing first responder status in AppKit.

### Extensions

Categorized extensions across Foundation, AppKit, CoreGraphics, and Audio frameworks:

| Category | Highlights |
|---|---|
| **Foundation** | `String` (padding, truncation, data conversion), `URL` (parent detection, query parameters, bookmark management), `Dictionary` (merging, key mapping), `TimeInterval` (mach time conversion), `UUID` (zero constants), `NumberFormatter` |
| **AppKit** | `NSView` (Auto Layout constraint helpers), `NSImage` (resizing, tinting), `NSWindow` (positioning), `NSEdgeInsets` (convenience inits) |
| **CoreGraphics** | `CGImage` (scaling), `CGRect` (square fitting), `CGSize` (equality init), `CGColor` (hex conversion) |
| **Audio** | `AUValue` (dB/linear conversion, normalization), `AVAudioTime` (host time utilities) |
| **XML** | `PlistUtilities` (dictionary/plist round-trip serialization via AEXML) |

### Entropy

Embedded [EntropyString](https://github.com/EntropyString/EntropyString-Swift) library for generating cryptographically random identifiers with configurable character sets and entropy levels (small, medium, large, session, token).

## Dependencies

| Package | Description |
|---|---|
| [spfk-audio-base](https://github.com/ryanfrancesconi/spfk-audio-base) | Shared audio type definitions |
| [spfk-filesystem](https://github.com/ryanfrancesconi/spfk-filesystem) | File system utilities, directory observation, Finder tags |
| [AEXML](https://github.com/tadija/AEXML) | XML parsing and generation |
| [spfk-testing](https://github.com/ryanfrancesconi/spfk-testing) | Test infrastructure (test target only) |

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
