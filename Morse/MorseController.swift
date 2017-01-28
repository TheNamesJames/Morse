//
//  MorseController.swift
//  Morse
//
//  Created by James Wilkinson on 26/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import Foundation

class MorseController {
    private(set) static var validCharacters: CharacterSet = {
        let uniqueValidChars = Set<String>(Morse.morseCodes.keys.map { String($0) } + Morse.morseCodes.keys.map { String($0).uppercased() })
        return CharacterSet(charactersIn: uniqueValidChars.joined())
    }()
    
    class func validate(_ string: String) -> (isValid: Bool, validatedString: String) {
        let validated = string.unicodeScalars
            .filter { validCharacters.contains($0) }
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
            .flatMap { Morse.morseCodes[$0] }
    }
    
    class func morseString(from morse: [[Morse]]) -> String {
        return morse
            .map { String($0.map { $0.rawValue }) }
            .joined(separator: " ")
    }
}
