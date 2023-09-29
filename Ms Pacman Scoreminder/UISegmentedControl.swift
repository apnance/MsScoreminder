//
//  UISegmentedControl.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 8/22/23.
//

import UIKit
import APNUtil

extension UISegmentedControl {

    override open func didMoveToSuperview() {
        
        super.didMoveToSuperview()
        
        addTarget(self,
                  action: #selector(addHaptic),
                  for: .valueChanged)
        
    }
    
    @objc private func addHaptic() {
        
        haptic(withStyle: .light)
        
    }
    
}
