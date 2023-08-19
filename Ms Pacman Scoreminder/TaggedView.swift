//
//  TaggedView.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 8/18/23.
//

import UIKit

/// Convenience UIView subclass that inserts a label showing this view's tag
/// value  into its subview in Interface Builder.
/// - note: this is used specifically in ScoreEditor.xib to arrange the
/// placeholder view for APNFlexKeypad buttons.
@IBDesignable class TaggedView: UIView {
    
    override func prepareForInterfaceBuilder() {
        
        let label                   = UILabel(frame: bounds)
        label.text                  = tag.description
        label.textAlignment         = .center
        label.minimumScaleFactor    = 0.5
        label.adjustsFontSizeToFitWidth = true
        
        label.textColor             = .white
        label.font = UIFont(name: "Futura-Bold", size: 12.0)
        
        layer.cornerRadius          = frame.width / 2.0
        addSubview(label)
        
    }
    
}
