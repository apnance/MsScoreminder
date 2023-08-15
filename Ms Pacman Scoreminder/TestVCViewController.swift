//
//  TestVCViewController.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 8/11/23.
//

import UIKit

class TestViewController: UIViewController {

    var editor = ScoreEditor()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        editor = ScoreEditor()
        
        (Bundle.main.loadNibNamed("ScoreEditor",
                                 owner: editor,
                                  options: nil)?.first as? UIView)?.constrainIn(view)
        
        editor.uiInit()
        
    }
    
}
