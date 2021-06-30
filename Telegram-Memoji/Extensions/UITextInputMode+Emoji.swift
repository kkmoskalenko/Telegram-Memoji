//
//  UITextInputMode+Emoji.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 30.06.2021.
//

import UIKit

extension UITextInputMode {
    static var emojiInputMode: UITextInputMode? {
        activeInputModes.first(where: {
            $0.primaryLanguage == "emoji"
        })
    }
    
    static var isEmojiEnabled: Bool {
        emojiInputMode != nil
    }
}
