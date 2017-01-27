//
//  NSLayoutConstraintExt.swift
//  Morse
//
//  Created by James Wilkinson on 25/01/2017.
//  Copyright © 2017 James Wilkinson. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    /** Creates new constraint with the same properties as `self` but with the input multiplier.\n
     If `automaticallyActivate` is `true`
     n.b. As this is a new constraint, `isActive` will be set to `false`. Also the exact value of `shouldBeArchived` will be undefined.
     */
    func withMultiplier(_ multiplier: CGFloat, automaticallyActivate: Bool = false) -> NSLayoutConstraint {
        NSLayoutConstraint.deactivate([self])
        
        let result = NSLayoutConstraint(item: firstItem, attribute: firstAttribute, relatedBy: relation, toItem: secondItem, attribute: secondAttribute, multiplier: multiplier, constant: constant)
        result.priority = priority
        result.shouldBeArchived = shouldBeArchived
        result.identifier = identifier
        
        if automaticallyActivate {
            NSLayoutConstraint.activate([result])
        }
        
        return result
    }
}
