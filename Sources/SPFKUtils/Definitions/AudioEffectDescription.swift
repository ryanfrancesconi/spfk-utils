// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

import AEXML
import AudioToolbox
import Foundation
import SPFKAudioBase

public struct AudioEffectDescription: Equatable {
    public static func == (
        lhs: AudioEffectDescription,
        rhs: AudioEffectDescription
    ) -> Bool {
        lhs.uid == rhs.uid
    }

    public var uid: String?
    public var index: Int?
    public var isBypassed: Bool = false
    public var isVisible: Bool = false
    public var name: String?

    /// The position and size of the window on screen
    public var frame: CGRect?

    public var presetID: String?

    public var fullStateDictionary: [String: Any]?

    public var componentDescription: AudioComponentDescription? {
        guard let uid else { return nil }
        return AudioComponentDescription(uid: uid)
    }

    public init(
        uid: String? = nil,
        index: Int? = nil,
        isBypassed: Bool = false,
        isVisible: Bool = false,
        name: String? = nil,
        frame: CGRect? = nil,
        fullStatePlist: AEXMLElement? = nil
    ) {
        self.uid = uid
        self.index = index
        self.isBypassed = isBypassed
        self.isVisible = isVisible
        self.name = name
        self.frame = frame

        if let fullStatePlist {
            parse(fullState: fullStatePlist)
        }
    }
}

extension AudioEffectDescription {
    /// plist of the current ui fullStateDictionary value
    public var fullStatePlist: AEXMLElement? {
        guard let fullStateDictionary else { return nil }
        return try? PlistUtilities.dictionaryToPlist(dictionary: fullStateDictionary).root
    }

    public mutating func parse(fullState: AEXMLElement) {
        fullStateDictionary = try? PlistUtilities.plistToDictionary(element: fullState)
    }
}
