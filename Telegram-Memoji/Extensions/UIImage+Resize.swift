//
//  UIImage+Resize.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 04.07.2021.
//

import UIKit

extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize = widthRatio > heightRatio ?
            CGSize(width: size.width * heightRatio,
                   height: size.height * heightRatio) :
            CGSize(width: size.width * widthRatio,
                   height: size.height * widthRatio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
