//
//  MorseController.swift
//  Morse
//
//  Created by James Wilkinson on 26/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import Foundation

class MorseController {
    
    private static let morse: [Character: [Morse]] = [
        "0": [.dash, .dash, .dash, .dash, .dash],
        "1": [.dot, .dash, .dash, .dash, .dash],
        "2": [.dot, .dot, .dash, .dash, .dash],
        "3": [.dot, .dot, .dot, .dash, .dash],
        "4": [.dot, .dot, .dot, .dot, .dash],
        "5": [.dot, .dot, .dot, .dot, .dot],
        "6": [.dash, .dot, .dot, .dot, .dot],
        "7": [.dash, .dash, .dot, .dot, .dot],
        "8": [.dash, .dash, .dash, .dot, .dot],
        "9": [.dash, .dash, .dash, .dash, .dot],
        "a": [.dot, .dash],
        "b": [.dash, .dot, .dot, .dot],
        "c": [.dash, .dot, .dash, .dot],
        "d": [.dash, .dot, .dot],
        "e": [.dot],
        "f": [.dot, .dot, .dash, .dot],
        "g": [.dash, .dash, .dot],
        "h": [.dot, .dot, .dot, .dot],
        "i": [.dot, .dot],
        "j": [.dot, .dash, .dash, .dash],
        "k": [.dash, .dot, .dash],
        "l": [.dot, .dash, .dot, .dot],
        "m": [.dash, .dash],
        "n": [.dash, .dot],
        "o": [.dash, .dash, .dash],
        "p": [.dot, .dash, .dash, .dot],
        "q": [.dash, .dash, .dot, .dash],
        "r": [.dot, .dash, .dot],
        "s": [.dot, .dot, .dot],
        "t": [.dash],
        "u": [.dot, .dot, .dash],
        "v": [.dot, .dot, .dot, .dash],
        "w": [.dot, .dash, .dash],
        "x": [.dash, .dot, .dot, .dash],
        "y": [.dash, .dot, .dash, .dash],
        "z": [.dash, .dash, .dot, .dot],
        ".": [.dot, .dash, .dot, .dash, .dot, .dash],
        ",": [.dash, .dash, .dot, .dot, .dash, .dash],
        "?": [.dot, .dot, .dash, .dash, .dot, .dot],
        "'": [.dot, .dash, .dash, .dash, .dash, .dot],
        "!": [.dash, .dot, .dash, .dot, .dash, .dash],
        "/": [.dash, .dot, .dot, .dash, .dot],
        "(": [.dash, .dot, .dash, .dash, .dot, .dash],
        ")": [.dash, .dot, .dash, .dash, .dot, .dash],
        "&": [.dot, .dash, .dot, .dot, .dot],
        ":": [.dash, .dash, .dash, .dot, .dot, .dot],
        ";": [.dash, .dot, .dash, .dot, .dash, .dot],
        "=": [.dash, .dot, .dot, .dot, .dash],
        "+": [.dot, .dash, .dot, .dash, .dot],
        "-": [.dash, .dot, .dot, .dot, .dot, .dash],
        "_": [.dot, .dot, .dash, .dash, .dot, .dash],
        "\"": [.dot, .dash, .dot, .dot, .dash, .dot],
        "$": [.dot, .dot, .dot, .dash, .dot, .dot, .dash],
        "@": [.dot, .dash, .dash, .dot, .dash, .dot],
        " ": [.space]
    ]
    
    private static let shared = MorseController()
    
    private(set) static var validCharacters: CharacterSet = {
        let uniqueValidChars = Set<String>(morse.keys.map { String($0) } + morse.keys.map { String($0).uppercased() })
        return CharacterSet(charactersIn: uniqueValidChars.joined())
    }()
    
    static let inputLimit = 120
    
    typealias TimerInvalidatorBlock = (isTransmitting: () -> Bool, cancel: () -> Void)
    
    enum Morse: Character {
        case dot = "•"
        case dash = "-"
        case space = " "
        
        var time: Int {
            switch self {
            case .dot:
                return 1
            case .dash:
                return 2
            case .space:
                return 3
            }
        }
    }
    
    class func validate(_ string: String) -> (isValid: Bool, validatedString: String) {
        let validated = string.unicodeScalars
            .filter { validCharacters.contains($0) }
            .prefix(inputLimit)
            .reduce("") { $0.0 + String($0.1) }
        
        return (string == validated, validated)
    }
    
    class func morseString(from string: String) -> String? {
        guard let morse = morse(from: string) else { return nil }
        return morseString(from: morse)
    }
    
    class func morse(from string: String) -> [[Morse]]? {
        let validated = validate(string)
        guard validated.isValid else {
            return nil
        }
        
        return validated.validatedString.lowercased().characters
            .flatMap { morse[$0] }
    }
    
    class func morseString(from morse: [[Morse]]) -> String {
        return morse
            .map { String($0.map { $0.rawValue }) }
            .joined(separator: " ")
    }
    
    class func transmit(_ string: String, block: @escaping (Bool) -> Void, reset: @escaping () -> Void) -> TimerInvalidatorBlock? {
        guard let morse = morse(from: string) else {
            return nil
        }
        return transmit(morse, block: block, reset: reset)
    }
    
    class func transmit(_ morse: [[Morse]], block: @escaping (Bool) -> Void, reset: @escaping () -> Void) -> TimerInvalidatorBlock {
        var remaining = morse
        var bipsRemaining: Int = 0
        
        func blockybloo() -> Bool {
            guard bipsRemaining == 0 else {
                defer {
                    bipsRemaining -= 1
                }
                if bipsRemaining == 1 {
                    block(false)
                }
                return true
            }
            guard !remaining.isEmpty else {
                return false
            }
            guard let word = remaining.first, let letter = word.first else {
                remaining = Array(remaining.dropFirst())
                return blockybloo()
            }
            bipsRemaining = letter.time
            remaining = [Array(word.dropFirst())] + Array(remaining.dropFirst())
            
            block(true)
            return true
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { (timer) in
            let transmitResult = blockybloo()
            guard transmitResult else {
                reset()
                timer.invalidate()
                return
            }
        }
        
        let isValidBlock: () -> Bool = { [weak timer] in
            timer?.isValid ?? false
        }
        let cancelBlock: () -> Void = { [weak timer, isValidBlock] in
            guard isValidBlock() else {
                return
            }
            reset()
            timer?.invalidate()
        }
        return (isValidBlock, cancelBlock)
    }
}
