//
//  MorseTransmitter.swift
//  Morse
//
//  Created by James Wilkinson on 27/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import Foundation

class MorseTransmitter {
    static let signalDuration: Double = 0.25
    
    typealias TimerInvalidatorBlock = (isTransmitting: () -> Bool, cancel: () -> Void)
    
    class func transmit(_ string: String, block: @escaping (Bool) -> Void, reset: @escaping () -> Void) -> TimerInvalidatorBlock? {
        guard let morse = MorseController.morse(from: string) else {
            return nil
        }
        return transmit(morse, block: block, reset: reset)
    }
    
    class func transmit(_ morse: [[Morse]], block: @escaping (Bool) -> Void, reset: @escaping () -> Void) -> TimerInvalidatorBlock {
        return transmit(convert(from: morse), block: block, reset: reset)
    }
    
    class func transmit(_ pulses: [Bool], block: @escaping (Bool) -> Void, reset: @escaping () -> Void) -> TimerInvalidatorBlock {
        var remaining = pulses
        
        let timer = Timer.scheduledTimer(withTimeInterval: signalDuration, repeats: true) { (timer) in
            guard let pulse = remaining.first else {
                reset()
                timer.invalidate()
                return
            }
            
            remaining = Array(remaining.dropFirst())
            
            block(pulse)
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
    
    class func signalDuration(for morse: [[Morse]]) -> Double {
        return Double(convert(from: morse).count) * signalDuration
    }
    
    /// Converts morse code into on/off pulses
    private class func convert(from morse: [[Morse]]) -> [Bool] {
        var result = [Bool]()
        for word in morse {
            for letter in word {
                for _ in 0..<letter.time {
                    result.append(letter != .space)
                }
                result.append(false)
            }
            result.append(false)
        }
        return result
    }
}
