// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

extension NameTemplate {
    /// Leaves room under the 255-byte file name limit for an extension and a collision number.
    public static let maximumNameByteCount = 240

    /// The file system's limit on one path component.
    public static let maximumLevelByteCount = 255

    /// The name part: every value substituted, then ``sanitizedName(_:)``. Empty when nothing
    /// rendered, which the caller replaces with a fallback.
    public func render(values: [String: Value], context: RenderContext) -> String {
        let pieces = render(parts, values: values, context: context)
        return Self.sanitizedName(pieces.map { $0 ?? "/" }.joined())
    }

    /// The folder part: one entry per `/` in the template's text, each ``sanitizedLevel(_:)`` on its
    /// own, with empty levels dropped. A `/` inside a value does not split.
    public func renderLevels(values: [String: Value], context: RenderContext) -> [String] {
        let pieces = render(parts, values: values, context: context)
        var levels = [""]

        for piece in pieces {
            if let piece {
                levels[levels.count - 1] += piece
            } else {
                levels.append("")
            }
        }

        return levels.map(Self.sanitizedLevel).filter { !$0.isEmpty }
    }

    /// Text pieces, with nil for each folder separator.
    private func render(_ parts: [Part], values: [String: Value], context: RenderContext) -> [String?] {
        var pieces: [String?] = []

        for part in parts {
            switch part {
            case let .literal(text):
                pieces.append(text)

            case .slash:
                pieces.append(nil)

            case let .token(token):
                pieces.append(token.render(values: values, context: context))

            case let .section(inner):
                let isFilled = inner.allSatisfy { part in
                    guard case let .token(token) = part else { return true }
                    return !token.render(values: values, context: context).trimmed.isEmpty
                }

                if isFilled {
                    pieces += render(inner, values: values, context: context)
                }
            }
        }

        return pieces
    }

    // MARK: - Sanitizing

    /// Trims whitespace and leading dots, which hide a file, replaces `/` and `:` with `-`, and
    /// shortens to ``maximumNameByteCount`` on whole characters. Never changes case.
    public static func sanitizedName(_ name: String) -> String {
        sanitized(name, maximumByteCount: maximumNameByteCount)
    }

    /// ``sanitizedName(_:)`` for one folder level, shortened to ``maximumLevelByteCount``.
    public static func sanitizedLevel(_ level: String) -> String {
        sanitized(level, maximumByteCount: maximumLevelByteCount)
    }

    private static func sanitized(_ name: String, maximumByteCount: Int) -> String {
        let cleaned = String(name.trimmed.drop { $0 == "." })
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        var byteCount = 0
        let kept = cleaned.prefix {
            byteCount += $0.utf8.count
            return byteCount <= maximumByteCount
        }

        return String(kept).trimmed
    }
}

// MARK: - Tokens

extension NameTemplate.Token {
    /// The first alternative that is not empty once trimmed, with the modifiers applied.
    func render(values: [String: NameTemplate.Value], context: NameTemplate.RenderContext) -> String {
        var chosen = ""

        for alternative in alternatives {
            let value: String = switch alternative {
            case let .literal(text): text
            case let .value(name, argument): Self.value(name: name, argument: argument, values: values, context: context).trimmed
            }

            if !value.trimmed.isEmpty {
                chosen = value
                break
            }
        }

        return modifiers.reduce(chosen) { $1.apply(to: $0) }
    }

    private static func value(
        name: String,
        argument: String?,
        values: [String: NameTemplate.Value],
        context: NameTemplate.RenderContext
    ) -> String {
        switch name {
        case "seq":
            return sequence(argument, context: context)

        case "collection":
            return context.collection

        default:
            // A value keyed `name:argument` answers that argument alone; `{field:x}` has no bare value.
            let keyed = argument.flatMap { values[name + ":" + $0] }

            switch keyed ?? (name == "field" ? nil : values[name]) {
            case let .text(text): return text
            case let .date(parts): return parts.formatted(argument ?? NameTemplate.DateParts.defaultPattern) ?? ""
            case nil: return ""
            }
        }
    }

    /// `{seq}` pads to the count's digits from 1; `{seq:W}` pads to at least `W`; `start=N` starts at `N`.
    private static func sequence(_ argument: String?, context: NameTemplate.RenderContext) -> String {
        var width = String(context.count).count
        var start = 1

        for option in (argument ?? "").split(separator: ",") {
            let option = option.trimmed

            if option.hasPrefix("start=") {
                start = Int(option.dropFirst("start=".count)) ?? start
            } else if let value = Int(option), value >= 0 {
                width = min(value, 20)
            }
        }

        let (number, overflow) = start.addingReportingOverflow(context.index - 1)
        guard !overflow else { return "" }

        let digits = String(number.magnitude)
        let padded = String(repeating: "0", count: max(0, width - digits.count)) + digits
        return number < 0 ? "-" + padded : padded
    }
}

extension NameTemplate.Token.Modifier {
    func apply(to value: String) -> String {
        switch name {
        case "upper":
            return value.uppercased()

        case "lower":
            return value.lowercased()

        case "title":
            return value.capitalized

        case "trim":
            return value.trimmed

        case "first":
            guard let count = argument.flatMap({ Int($0) }), count >= 0 else { return value }
            return String(value.prefix(count))

        case "replace":
            guard let argument, let equals = argument.firstIndex(of: "=") else { return value }
            let target = String(argument[..<equals])
            guard !target.isEmpty else { return value }
            return value.replacingOccurrences(of: target, with: argument[argument.index(after: equals)...])

        default:
            return value
        }
    }
}

extension StringProtocol {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
