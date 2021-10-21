//
//  Utils.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/21/21.
//

import UIKit

struct Utils {
    
    struct UI {

        /// Adds drop shadows to all elements contained in internal views array
        static func addShadows(to: [UIView],
                               withOpacity opacity: Double = Configs.UI.Shadow.defaultOpacity) {
            
            to.forEach{ addShadows(to: $0,
                                   withOpacity: opacity) }
            
        }
        
        /// Adds drop shadows to all `UIView`
        static func addShadows(to: UIView,
                               withOpacity opacity: Double = Configs.UI.Shadow.defaultOpacity) {
            
            to.layer.shadowColor   = UIColor.black.cgColor
            to.layer.shadowOffset  = CGSize(width: Configs.UI.Shadow.defaultWidth,
                                            height: Configs.UI.Shadow.defaultHeight)
            to.layer.shadowOpacity = Float(opacity)
            
        }
        
    }
    
}
