# SPFKUtils
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-utils)](https://github.com/ryanfrancesconi/spfk-utils/tags)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-utils%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-utils)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-utils%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-utils)

Support utilities for the packages above spfk-base. The data and UI layers of both products reach
it; nothing embeds it on its own.

It holds utilities that need more than Foundation: AppKit, CoreGraphics and Core Animation
extensions, display-link timers, bounded-concurrency batch work including batch file conversion, a
disk cache for decoded images, and CSV and XML helpers. It also holds the state a sidebar and a table
persist, such as outline nodes, expansion, column layout and sort, because data packages need that
state without depending on a UI package.

## Scope

spfk-base is the Foundation-level floor; spfk-utils sits above it and above spfk-filesystem and
spfk-image, and may use AppKit. It is for utilities in the plain sense: something with no subject of
its own that more than one package needs. It is not a grab bag. A type belongs in the package whose
subject it is (audio vocabulary in spfk-audio-base, time in spfk-time, views in spfk-ui), and a type
that fits nowhere yet means a package is missing, not that it goes here.

`SPFKSymbol` and `SPFKSchemeColor` are UI definitions kept here deliberately: non-UI packages use
them as default arguments, and spfk-ui already depends on spfk-playlist-data, so they cannot move up.

## Vendored code

Includes [EntropyString](https://github.com/EntropyString/EntropyString-Swift) under its MIT license,
for random identifiers.

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
