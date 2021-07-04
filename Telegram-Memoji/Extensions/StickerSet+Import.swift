//
//  StickerSet+Import.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 04.07.2021.
//

import Foundation
import TelegramStickersImport

extension StickerSet {
    func importToTelegram() throws {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let stickerSet = TelegramStickersImport.StickerSet(
            software: bundleIdentifier, isAnimated: false)
        
        for sticker in stickers?.array ?? [] {
            guard
                let sticker = sticker as? Sticker,
                let imageData = sticker.imageData,
                let emojis = sticker.emojis
            else { continue }
            
            try stickerSet.addSticker(
                data: .image(imageData),
                emojis: emojis.map(String.init)
            )
        }
        
        try stickerSet.import()
    }
}

// MARK: - Import Errors

typealias StickersError = TelegramStickersImport.StickersError

extension StickersError {
    var message: String {
        switch self {
            case .fileTooBig:
                return "One or more stickers exceed the maximum file size."
            case .invalidDimensions:
                return "One or more stickers have invalid dimensions."
            case .countLimitExceeded:
                return "The sticker set has reached the maximum number of items (120)."
            case .dataTypeMismatch:
                return "One or more stickers are of an invalid data type."
            case .setIsEmpty:
                return "The sticker set is empty."
        }
    }
}
