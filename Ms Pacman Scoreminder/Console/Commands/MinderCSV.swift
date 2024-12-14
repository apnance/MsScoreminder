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
struct MinderCSV: Command {
    
    weak var statMan: StatManager?
    
    // - MARK: Command Requirements
    var commandToken    = Configs.Console.Commands.CSV.token
    
    var isGreedy        = false
    
    var category        = Configs.Console.Commands.category
    
    var helpText        = Configs.Console.Commands.CSV.helpText
    
    func process(_ args: [String]?) -> CommandOutput {
        
        let csv = statMan!.csv
        
        var output  = CommandOutput.output(csv)
        output      += CommandOutput.note("copied to pasteboard.",
                                          newLines: 1)
        
        // Pasteboard
        printToClipboard(csv)
        
        return output /*EXIT*/
        
    }
    
}

