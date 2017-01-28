//
//  UIFontExt.swift
//  Morse
//
//  Created by James Wilkinson on 28/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import UIKit

extension UIFont {
    enum CustomFamily {
        case playfairDisplay
        
        fileprivate var name: String {
            switch self {
            case .playfairDisplay:
                return "Playfair Display"
            }
        }
    }
    
    static func customFont(_ family: CustomFamily, size: CGFloat) -> UIFont {
        return UIFont(name: family.name, size: size)!
    }
}
