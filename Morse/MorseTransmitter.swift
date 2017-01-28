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
            guard let word = remaining.first else {
                return false
            }
            guard let letter = word.first else {
                defer {
                    remaining = Array(remaining.dropFirst())
                }
                return true
            }
            
            bipsRemaining = letter.time
            remaining = [Array(word.dropFirst())] + Array(remaining.dropFirst())
            
            block(letter != .space)
            return true
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: signalDuration, repeats: true) { (timer) in
            let transmitResult = blockybloo()
            guard transmitResult else {
                reset()
                timer.invalidate()
                return
            }
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
}
