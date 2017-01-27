//
//  MorseController.swift
//  Morse
//
//  Created by James Wilkinson on 26/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import Foundation

private let morseCodes = [
    "0": "-----",
    "1": ".----",
    "2": "..---",
    "3": "...--",
    "4": "....-",
    "5": ".....",
    "6": "-....",
    "7": "--...",
    "8": "---..",
    "9": "----.",
    "a": ".-",
    "b": "-...",
    "c": "-.-.",
    "d": "-..",
    "e": ".",
    "f": "..-.",
    "g": "--.",
    "h": "....",
    "i": "..",
    "j": ".---",
    "k": "-.-",
    "l": ".-..",
    "m": "--",
    "n": "-.",
    "o": "---",
    "p": ".--.",
    "q": "--.-",
    "r": ".-.",
    "s": "...",
    "t": "-",
    "u": "..-",
    "v": "...-",
    "w": ".--",
    "x": "-..-",
    "y": "-.--",
    "z": "--..",
    ".": ".-.-.-",
    ",": "--..--",
    "?": "..--..",
    "!": "-.-.--",
    "-": "-....-",
    "/": "-..-.",
    "@": ".--.-.",
    "(": "-.--.",
    ")": "-.--.-",
    " ": "/"
]

class MorseController {
    private static let shared = MorseController()
    
    private(set) static var validCharacters: CharacterSet = {
        let uniqueValidChars = Set<String>(morseCodes.keys + morseCodes.keys.map { $0.uppercased() })
        return CharacterSet(charactersIn: uniqueValidChars.joined())
    }()
    
    static let inputLimit = 120
    
    typealias TimerInvalidatorBlock = () -> Void
    
    enum Morse: Character {
        case dot = "."
        case dash = "-"
        case space = "/"
        
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
        return morse(from: string)?
            .map { String($0.map { $0.rawValue }) }
            .joined(separator: " ")
    }
    
    class func morse(from string: String) -> [[Morse]]? {
        let validated = validate(string)
        guard validated.isValid else {
            return nil
        }
        
        return validated.validatedString.lowercased().characters
            .flatMap { morseCodes[String($0)] }
            .flatMap { $0.characters.flatMap { Morse(rawValue: $0) } }
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
        
        return {
            reset()
            timer.invalidate()
        }
    }
}
