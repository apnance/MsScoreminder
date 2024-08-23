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
    
    @discardableResult init(consoleView: ConsoleView, 
                            statManager: StatManager) {
        
        self.consoleView = consoleView
        self.statMan = statManager
        
        load()
        
    }
    
    var consoleView: ConsoleView
    var statMan: StatManager
    
    var commandGroups: [CommandGroup]? { [scoreminderCommandGroup] }
    
    var configs: ConsoleViewConfigs? {
        
        var configs = ConsoleViewConfigs()
        
        configs.fgColorPrompt                   = UIColor.darkPink
        configs.fgColorCommandLine              = UIColor.darkPink
        configs.fgColorScreenInput              = UIColor.orange
        configs.fgColorScreenOutput             = UIColor.banana
        configs.borderWidth                     = 1.0
        configs.borderColor                     = UIColor.pear.cgColor
        configs.bgColor                         = .black.pointSevenAlpha
        configs.fontName                        = "Menlo"
        configs.fontSize                        = 10
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
    
    var scoreminderCommandGroup: CommandGroup {
        
        return [
            //                HERE...
            // TODO: Clean Up - Implement first n, last n, nuke, del, add
            //       Do this as an addition to ConsoleView.DataManagerConfigurator.
            Command(token:      Configs.Console.Command.Played.token,
                    processor:  comPlayed,
                    category:   Configs.Console.Command.Played.category,
                    helpText:   Configs.Console.Command.Played.helpText),
            
            Command(token:      Configs.Console.Command.CSV.token,
                    processor:  comCSV,
                    category:   Configs.Console.Command.CSV.category,
                    helpText:   Configs.Console.Command.CSV.helpText),
            
        ]
        
        func comPlayed(_ args:[String]?, console: ConsoleView) -> CommandOutput {
            
            var arg1 = args.elementNum(0)
            
            // Today?
            arg1 = (arg1.lowercased() == "today") ? Date().simple : arg1
            
            if let date = arg1.simpleDateMaybe {
                
                return console.formatCommandOutput(statMan.played(date))
                
            } else {
                
                return console.formatCommandOutput(statMan.played())
                
            }
            
        }
        
        
        /// Builds and returns a comma separated values list of all recorded `Score`s
        ///
        /// - Parameter _: does not require or process arguments.
        /// - Returns: CSV version of all  recorded`Score` data
        func comCSV(_:[String]?, console: ConsoleView) -> CommandOutput {
            
            if let csv = (console.viewController as? ViewController)?.statMan.csv {
                
                var atts = console.formatCommandOutput("""
                          \(csv)
                          [Note: above output copied to pasteboard]
                          """)
                
                atts.foregroundColor    = UIColor.pear
                
                printToClipboard(csv)
                
                return atts /*EXIT*/
                
            } else {
                
                return console.format("Error retrieving .csv data.",
                                      target: .outputWarning)
                
            }
            
        }
        
    }
    
}
