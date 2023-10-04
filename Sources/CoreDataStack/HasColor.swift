//
//  HasColor.swift
//  
//
//  Created by Yauhen Rusanau on 2022-11-27.
//

import SwiftUI

public protocol HasStoredColor: AnyObject {
    var colorRed: Double { get set }
    var colorGreen: Double { get set }
    var colorBlue: Double { get set }
    var colorAlpha: Double { get set }
}

public extension HasStoredColor {
    #if os(macOS)
    typealias SystemColor = NSColor
    #else
    typealias SystemColor = UIColor
    #endif
    
    var color: Color {
        get {
            Color(red: colorRed, green: colorGreen, blue: colorBlue, opacity: colorAlpha)
        }
        set {
            guard let components = SystemColor(newValue).cgColor.components else { return }
            
            switch components.count {
            case 1:
                colorRed = components[0]
                colorGreen = components[0]
                colorBlue = components[0]
                colorAlpha = 1
            case 2:
                colorRed = components[0]
                colorGreen = components[0]
                colorBlue = components[0]
                colorAlpha = components[1]
            case 3:
                colorRed = components[0]
                colorGreen = components[1]
                colorBlue = components[2]
                colorAlpha = 1
            case 4:
                colorRed = components[0]
                colorGreen = components[1]
                colorBlue = components[2]
                colorAlpha = components[3]
            default:
                break
            }
        }
    }
}
