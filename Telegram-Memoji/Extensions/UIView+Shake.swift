//
//  UIView+Shake.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 03.07.2021.
//

import UIKit

extension UIView {
    private static let shakeAnimationKey = "ShakeAnimation"
    
    func startShaking() {
        let shakeAnimation = CABasicAnimation(
            keyPath: "transform.rotation")
        let startAngle: Float = (-2) * .pi / 180
        let stopAngle = -startAngle
        
        shakeAnimation.fromValue = NSNumber(value: startAngle)
        shakeAnimation.toValue = NSNumber(value: 3 * stopAngle)
        
        shakeAnimation.repeatCount = .greatestFiniteMagnitude
        shakeAnimation.autoreverses = true
        shakeAnimation.duration = 0.15
        shakeAnimation.timeOffset = 290 * drand48()
        
        layer.add(shakeAnimation, forKey: Self.shakeAnimationKey)
    }
    
    func stopShaking() {
        layer.removeAnimation(forKey: Self.shakeAnimationKey)
    }
}
