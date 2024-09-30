//
//  MinderOutputCSV.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 9/29/24.
//

import UIKit
import APNUtil
import ConsoleView

/// Outputs the saved score data to the screen *and* to the pasteboards as a .csv
@available(iOS 15, *)
struct MinderOutputCSV: Command {
    
    // - MARK: Command Requirements
    var console: Console
    
    var commandToken    = Configs.Console.Commands.CSV.token
    
    var isGreedy        = false
    
    var category        = Configs.Console.Commands.category
    
    var helpText        = Configs.Console.Commands.CSV.helpText
    
    func process(_ args: [String]?) -> CommandOutput {
        
        if let csv = (console.screen as? ViewController)?.statMan.csv {
            
            var atts = screen.formatCommandOutput("""
                      \(csv)
                      [Note: above output copied to pasteboard]
                      """)
            
            // Format
            atts.formatted.foregroundColor = UIColor.pear
            
            // Pasteboard
            printToClipboard(csv)
            
            return atts /*EXIT*/
            
        } else {
            
            return screen.format("Error retrieving .csv data.",
                                  target: .outputWarning)
            
        }
        
    }
}

