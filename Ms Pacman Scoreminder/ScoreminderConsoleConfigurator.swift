//
//  ScoreminderConsoleConfigurator.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 7/21/24.
//

import UIKit
import APNUtil
import ConsoleView

struct ScoreminderConsoleConfigurator: ConsoleConfigurator {
    
    @discardableResult init(consoleView: ConsoleView) {
        
        self.consoleView = consoleView
        
        load()
        
    }
    
    var consoleView: ConsoleView
    
    var commandGroups: [CommandGroup] { [ScoreminderCommandGroup(consoleView: consoleView)] }
    
    var configs: ConsoleViewConfigs {
        
        var configs = ConsoleViewConfigs()
        
        configs.fgColorPrompt                   = UIColor.darkPink
        configs.fgColorCommandLine              = UIColor.darkPink
        configs.fgColorScreenInput              = UIColor.orange
        configs.fgColorScreenOutput             = UIColor.banana
        configs.borderWidth                     = 1.0
        configs.borderColor                     = UIColor.pear.cgColor
        configs.bgColor                         = .black.pointSevenAlpha
        configs.fontName                        = "Futura"
        configs.fontSize                        = 15
        configs.shouldHideOnScreenTap           = true
        configs.shouldMakeCommandFirstResponder = false
        
        configs.fgColorHistoryBarCommand            = UIColor.msPink
        configs.fgColorHistoryBarCommandArgument    = UIColor.msBlue
        configs.bgColorHistoryBarMain               = UIColor.banana.pointNineAlpha
        configs.bgColorHistoryBarButtons            = .white
        
        configs.aboutScreen =     """
                                    
                                       Welcome
                                         to
                                       Ms. Scoreminder \("v\(Bundle.appVersion)")
                                    
                                    """
        
        return configs
        
    }
    
    fileprivate class ScoreminderCommandGroup: CommandGroup {
        
        private let consoleView: ConsoleView
        
        init(consoleView: ConsoleView) {
            
            self.consoleView = consoleView
            
        }
        
        var commands: [Command] {
            [
                
                // TODO: Clean Up - Implement first n, last n, nuke, del, add
                Command(token: Configs.Console.Command.CSV.token,
                        process: comCSV,
                        category: Configs.Console.Command.category,
                        helpText:  Configs.Console.Command.CSV.helpText),
                
            ]
        }
        
        /// Builds and returns a comma separated values list of `ArchivedPuzzle`
        /// data in `archive`
        /// - Parameter _: does not require or process arguments.
        /// - Returns: CSV version of all `ArchivedPuzzle` data  in `archive`
        func comCSV(_:[String]?) -> CommandOutput {
            
            if let csv = (consoleView.viewController as? ViewController)?.statMan.csv {
                
                  var atts = consoleView.formatCommandOutput("""
                          \(csv)
                          [Note: above output copied to pasteboard]
                          """)
                
                atts.foregroundColor    = UIColor.pear
                
                printToClipboard(csv)
                
                return atts /*EXIT*/
                
            } else {
                
                return consoleView.format("Error retrieving .csv data.",
                                          target: .outputWarning)
                
            }
            
        }
        
    }
    
}
