// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import Compression
import Foundation

enum ZipArchiveError: Error, Equatable, LocalizedError {
    case notAZipArchive
    case truncated
    case zip64Unsupported
    case encrypted(String)
    case unsupportedMethod(String, UInt16)
    case corruptEntry(String)
    case missingEntry(String)

    var errorDescription: String? {
        switch self {
        case .notAZipArchive: "The file is not a zip archive."
        case .truncated: "The zip archive is truncated."
        case .zip64Unsupported: "ZIP64 archives are not supported."
        case let .encrypted(name): "\"\(name)\" is encrypted."
        case let .unsupportedMethod(name, method): "\"\(name)\" uses unsupported compression method \(method)."
        case let .corruptEntry(name): "\"\(name)\" is corrupt."
        case let .missingEntry(name): "The archive has no \"\(name)\"."
        }
    }
}

/// The subset of the zip format an Office Open XML package needs: stored and deflated entries,
/// no ZIP64, no encryption.
enum ZipArchive {
    static let localHeaderSignatureBytes: [UInt8] = [0x50, 0x4B, 0x03, 0x04]

    private static let localHeaderSignature: UInt32 = 0x0403_4B50
    private static let centralHeaderSignature: UInt32 = 0x0201_4B50
    private static let endOfCentralDirectorySignature: UInt32 = 0x0605_4B50
    private static let stored: UInt16 = 0
    private static let deflated: UInt16 = 8

    // MARK: - Reading

    /// Every entry's uncompressed bytes, keyed by path. Each entry's CRC-32 is checked.
    static func entries(of data: Data) throws -> [String: Data] {
        let bytes = [UInt8](data)
        let endRecord = try findEndOfCentralDirectory(bytes)
        let entryCount = Int(bytes.u16(endRecord + 10))
        var offset = Int(bytes.u32(endRecord + 16))

        guard entryCount != 0xFFFF, offset != 0xFFFF_FFFF else { throw ZipArchiveError.zip64Unsupported }

        var result = [String: Data]()

        for _ in 0 ..< entryCount {
            guard offset + 46 <= bytes.count, bytes.u32(offset) == centralHeaderSignature else {
                throw ZipArchiveError.truncated
            }

            let flags = bytes.u16(offset + 8)
            let method = bytes.u16(offset + 10)
            let crc = bytes.u32(offset + 16)
            let compressedSize = Int(bytes.u32(offset + 20))
            let size = Int(bytes.u32(offset + 24))
            let nameLength = Int(bytes.u16(offset + 28))
            let extraLength = Int(bytes.u16(offset + 30))
            let commentLength = Int(bytes.u16(offset + 32))
            let localOffset = Int(bytes.u32(offset + 42))

            guard offset + 46 + nameLength <= bytes.count else { throw ZipArchiveError.truncated }

            let name = String(decoding: bytes[offset + 46 ..< offset + 46 + nameLength], as: UTF8.self)
            offset += 46 + nameLength + extraLength + commentLength

            if name.hasSuffix("/") { continue }

            guard compressedSize != 0xFFFF_FFFF, size != 0xFFFF_FFFF else { throw ZipArchiveError.zip64Unsupported }
            guard flags & 1 == 0 else { throw ZipArchiveError.encrypted(name) }

            guard localOffset + 30 <= bytes.count, bytes.u32(localOffset) == localHeaderSignature else {
                throw ZipArchiveError.truncated
            }

            let dataStart = localOffset + 30 + Int(bytes.u16(localOffset + 26)) + Int(bytes.u16(localOffset + 28))

            guard dataStart + compressedSize <= bytes.count else { throw ZipArchiveError.truncated }

            let compressed = bytes[dataStart ..< dataStart + compressedSize]
            let content: [UInt8]

            switch method {
            case stored:
                content = Array(compressed)
            case deflated:
                content = try inflate(compressed, size: size, name: name)
            default:
                throw ZipArchiveError.unsupportedMethod(name, method)
            }

            guard content.count == size, CRC32.checksum(content) == crc else {
                throw ZipArchiveError.corruptEntry(name)
            }

            result[name] = Data(content)
        }

        return result
    }

    private static func findEndOfCentralDirectory(_ bytes: [UInt8]) throws -> Int {
        guard bytes.count >= 22 else { throw ZipArchiveError.notAZipArchive }

        // The record is 22 bytes plus a comment of at most 65,535.
        let lowest = max(0, bytes.count - 22 - 0xFFFF)

        for offset in stride(from: bytes.count - 22, through: lowest, by: -1)
            where bytes.u32(offset) == endOfCentralDirectorySignature {
            return offset
        }

        throw ZipArchiveError.notAZipArchive
    }

    private static func inflate(_ compressed: ArraySlice<UInt8>, size: Int, name: String) throws -> [UInt8] {
        guard size > 0 else { return [] }

        var output = [UInt8](repeating: 0, count: size)

        let written = compressed.withUnsafeBufferPointer { source in
            output.withUnsafeMutableBufferPointer { destination in
                guard let sourceBase = source.baseAddress, let destinationBase = destination.baseAddress else { return 0 }
                return compression_decode_buffer(destinationBase, size, sourceBase, source.count, nil, COMPRESSION_ZLIB)
            }
        }

        guard written == size else { throw ZipArchiveError.corruptEntry(name) }
        return output
    }

    // MARK: - Writing

    /// A zip archive of `entries`, in the order given. An entry is deflated unless that would not
    /// make it smaller. Timestamps are fixed at 1980-01-01, so equal input gives equal output.
    static func archive(_ entries: [(path: String, data: Data)]) -> Data {
        var output = [UInt8]()
        var central = [UInt8]()

        for (path, data) in entries {
            let content = [UInt8](data)
            let crc = CRC32.checksum(content)
            let deflatedContent = deflate(content)
            let method = deflatedContent == nil ? stored : deflated
            let body = deflatedContent ?? content
            let name = Array(path.utf8)
            let localOffset = output.count

            // Version 2.0, no flags, DOS time 00:00 and date 1980-01-01.
            var common = [UInt8]()
            common.append(u16: 20)
            common.append(u16: 0)
            common.append(u16: method)
            common.append(u16: 0)
            common.append(u16: 0x21)
            common.append(u32: crc)
            common.append(u32: UInt32(body.count))
            common.append(u32: UInt32(content.count))
            common.append(u16: UInt16(name.count))
            common.append(u16: 0)

            output.append(u32: localHeaderSignature)
            output += common
            output += name
            output += body

            central.append(u32: centralHeaderSignature)
            central.append(u16: 20)
            central += common
            central.append(u16: 0) // comment length
            central.append(u16: 0) // disk number
            central.append(u16: 0) // internal attributes
            central.append(u32: 0) // external attributes
            central.append(u32: UInt32(localOffset))
            central += name
        }

        let centralOffset = output.count
        output += central

        output.append(u32: endOfCentralDirectorySignature)
        output.append(u16: 0)
        output.append(u16: 0)
        output.append(u16: UInt16(entries.count))
        output.append(u16: UInt16(entries.count))
        output.append(u32: UInt32(central.count))
        output.append(u32: UInt32(centralOffset))
        output.append(u16: 0)

        return Data(output)
    }

    /// Raw deflate, or `nil` when the result would not be smaller than `content`.
    private static func deflate(_ content: [UInt8]) -> [UInt8]? {
        guard content.count > 0 else { return nil }

        var output = [UInt8](repeating: 0, count: content.count)

        let written = content.withUnsafeBufferPointer { source in
            output.withUnsafeMutableBufferPointer { destination in
                guard let sourceBase = source.baseAddress, let destinationBase = destination.baseAddress else { return 0 }
                return compression_encode_buffer(destinationBase, content.count, sourceBase, content.count, nil, COMPRESSION_ZLIB)
            }
        }

        // 0 means the output did not fit in a buffer the size of the input.
        guard written > 0, written < content.count else { return nil }
        return Array(output.prefix(written))
    }
}

// MARK: - CRC-32

/// The CRC-32 zip uses (IEEE 802.3, reflected polynomial `0xEDB88320`).
enum CRC32 {
    private static let table: [UInt32] = (0 ..< 256).map { index in
        var value = UInt32(index)
        for _ in 0 ..< 8 {
            value = value & 1 == 1 ? 0xEDB8_8320 ^ (value >> 1) : value >> 1
        }
        return value
    }

    static func checksum(_ bytes: some Sequence<UInt8>) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in bytes {
            crc = table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFF_FFFF
    }
}

// MARK: - Little-endian fields

private extension [UInt8] {
    func u16(_ offset: Int) -> UInt16 {
        UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    func u32(_ offset: Int) -> UInt32 {
        UInt32(u16(offset)) | UInt32(u16(offset + 2)) << 16
    }

    mutating func append(u16 value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8(value >> 8))
    }

    mutating func append(u32 value: UInt32) {
        append(u16: UInt16(value & 0xFFFF))
        append(u16: UInt16(value >> 16))
    }
}
