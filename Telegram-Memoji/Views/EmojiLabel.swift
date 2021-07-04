//
//  EmojiLabel.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 04.07.2021.
//

import UIKit

final class EmojiLabel: UILabel {
    private static let cursorThickness: CGFloat = 2
    
    private lazy var cursorLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = tintColor.cgColor
        layer.cornerRadius = 0.5 * Self.cursorThickness
        layer.masksToBounds = true
        return layer
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        layer.addSublayer(cursorLayer)
        animateCursor()
        
        let notificationName = UIApplication
            .didBecomeActiveNotification
        NotificationCenter.default.addObserver(
            self, selector: #selector(animateCursor),
            name: notificationName, object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let textRect = textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        let cursorSize = CGSize(width: Self.cursorThickness, height: font.pointSize)
        let cursorOrigin = CGPoint(x: textRect == .zero ? bounds.midX : textRect.maxX,
                                   y: 0.5 * (bounds.height - cursorSize.height))
        
        cursorLayer.frame = CGRect(origin: cursorOrigin, size: cursorSize)
    }
    
    var characterCount: Int { text?.count ?? 0 }
}

// MARK: - Cursor Animation

extension EmojiLabel {
    private static let animationKey = "BlinkAnimation"
    
    @objc private func animateCursor() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 0.5
        animation.timingFunction = .init(name: .easeInEaseOut)
        animation.autoreverses = true
        animation.repeatCount = .greatestFiniteMagnitude
        cursorLayer.add(animation, forKey: Self.animationKey)
    }
}
