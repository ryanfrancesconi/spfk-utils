import Foundation

extension UUID {
    public static let zero = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
}

public enum UUIDConstant: UInt8, CaseIterable, Sendable{
    case _0 = 0
    case _1
    case _2
    case _3
    case _4
    case _5
    case _6
    case _7
    case _8
    case _9
    case _10
    
    public var uuid: UUID {
        UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rawValue))
    }
}
