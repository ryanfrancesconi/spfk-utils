// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Foundation

/// How an export names its files, before the extension and before ``BatchOutputClaims`` numbers
/// any that collide. Every scheme renders through a ``NameTemplate``.
public struct ExportNaming: Sendable, Hashable, Codable {
    public enum Scheme: String, Sendable, Hashable, Codable, CaseIterable {
        case fileName
        case title
        case sequential
        case collectionNameWithNumber
        case custom
    }

    public var scheme: Scheme

    /// Leads each name under ``Scheme/sequential``; `{text}` in a template.
    public var prefix: String

    /// The source of the ``Scheme/custom`` template.
    public var template: String

    /// The ``NameTemplate/currentVersion`` the template was written at.
    public var templateVersion: Int

    public init(
        scheme: Scheme = .fileName,
        prefix: String = "",
        template: String = "",
        templateVersion: Int = NameTemplate.currentVersion
    ) {
        self.scheme = scheme
        self.prefix = prefix
        self.template = template
        self.templateVersion = templateVersion
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scheme = try container.decode(Scheme.self, forKey: .scheme)
        prefix = try container.decodeIfPresent(String.self, forKey: .prefix) ?? ""
        template = try container.decodeIfPresent(String.self, forKey: .template) ?? ""
        templateVersion = try container.decodeIfPresent(Int.self, forKey: .templateVersion) ?? NameTemplate.currentVersion
    }

    private static let fileNameTemplate = NameTemplate("{name}")
    private static let titleTemplate = NameTemplate("{title?name}")
    private static let sequentialTemplate = NameTemplate("[{text} ]{seq}")
    private static let collectionTemplate = NameTemplate("[{collection} ]{seq}")

    /// The scheme's preset, or the custom template.
    public var nameTemplate: NameTemplate {
        switch scheme {
        case .fileName: Self.fileNameTemplate
        case .title: Self.titleTemplate
        case .sequential: Self.sequentialTemplate
        case .collectionNameWithNumber: Self.collectionTemplate
        case .custom: NameTemplate(template)
        }
    }

    /// One base name per item, in the order given, which is the order `{seq}` counts in.
    ///
    /// A name that renders empty falls back to the item's `name` value, sanitized.
    public func baseNames<Item>(
        for items: [Item],
        values: (Item) -> [String: NameTemplate.Value],
        collectionName: String
    ) -> [String] {
        let template = nameTemplate

        return items.indices.map {
            baseName(at: $0, of: items, values: values, collectionName: collectionName, template: template)
        }
    }

    /// The base name ``baseNames(for:values:collectionName:)`` gives the item at `index`, reading
    /// only that item's values.
    public func baseName<Item>(
        at index: Int,
        of items: [Item],
        values: (Item) -> [String: NameTemplate.Value],
        collectionName: String
    ) -> String {
        baseName(at: index, of: items, values: values, collectionName: collectionName, template: nameTemplate)
    }

    private func baseName<Item>(
        at index: Int,
        of items: [Item],
        values: (Item) -> [String: NameTemplate.Value],
        collectionName: String,
        template: NameTemplate
    ) -> String {
        var values = values(items[index])
        values["text"] = .text(prefix)

        let context = NameTemplate.RenderContext(index: index + 1, count: items.count, collection: collectionName)
        let name = template.render(values: values, context: context)

        guard name.isEmpty, case let .text(fileName)? = values["name"] else { return name }
        return NameTemplate.sanitizedName(fileName)
    }
}
