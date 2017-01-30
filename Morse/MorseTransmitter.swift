//
//  MorseTransmitter.swift
//  Morse
//
//  Created by James Wilkinson on 27/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import Foundation

class MorseTransmitter {
    static let pulseDuration: Double = 0.25
    
    typealias SignalBlock = (Bool, _ remaining: Double) -> Void
    
    typealias TimerInvalidatorBlock = (isTransmitting: () -> Bool, cancel: () -> Void)
    
    class func transmit(_ string: String, block: @escaping SignalBlock, reset: @escaping () -> Void) -> TimerInvalidatorBlock? {
        guard let morse = MorseController.morse(from: string) else {
            return nil
        }
        return transmit(morse, block: block, reset: reset)
    }
    
    class func transmit(_ morse: [[Morse]], block: @escaping SignalBlock, reset: @escaping () -> Void) -> TimerInvalidatorBlock {
        return transmit(convert(from: morse), block: block, reset: reset)
    }
    
    class func transmit(_ pulses: [Bool], block: @escaping SignalBlock, reset: @escaping () -> Void) -> TimerInvalidatorBlock {
        var remaining = pulses
        
        let timer = Timer.scheduledTimer(withTimeInterval: pulseDuration, repeats: true) { (timer) in
            guard let pulse = remaining.first else {
                reset()
                timer.invalidate()
                return
            }
            
            block(pulse, transmitDuration(for: remaining))
            
            remaining = Array(remaining.dropFirst())
        }
        
        RunLoop.current.add(timer, forMode: .commonModes)
        
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
    
    class func transmitDuration(for morse: [[Morse]]) -> Double {
        return transmitDuration(for: convert(from: morse))
    }
    
    class func transmitDuration(for pulses: [Bool]) -> Double {
        return Double(pulses.count) * pulseDuration
    }
    
    /// Converts morse code into on/off pulses
    private class func convert(from morse: [[Morse]]) -> [Bool] {
        var result = [Bool]()
        for (i, word) in morse.enumerated() {
            for letter in word {
                result.append(contentsOf: [Bool](repeating: letter != .space, count: letter.time))
                result.append(false)
            }
            if i != morse.count-1 {
                result.append(false)
                result.append(false)
            }
        }
        return Array(result.dropLast())
    }
}
