# SPFKUtils
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
- **AudioEffectDescription** — Descriptor for audio effect components (manufacturer, type, subtype).
- **BundleProperties** — Typed access to common `Bundle.main` info dictionary values.
- **HardwareInfo** — System hardware queries (model identifier, machine name).
- **ProcessHandler** — Launch and manage external processes with stdout/stderr capture.
- **StereoState** — Enumeration of stereo routing states (stereo, mono, left, right, swapped).

### UI

- **HexColor / RGBAColor** — Hex string and RGBA representations for cross-platform color handling.
- **SPFKColor / ComponentColor** — Platform-agnostic color types bridging AppKit and UIKit.
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
| [Checksum](https://github.com/rnine/Checksum) | File checksum utilities |

## About

Spongefork (SPFK) is the personal software projects of [Ryan Francesconi](https://github.com/ryanfrancesconi). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2016 to 2025 he was the lead macOS developer at [Audio Design Desk](https://add.app).
