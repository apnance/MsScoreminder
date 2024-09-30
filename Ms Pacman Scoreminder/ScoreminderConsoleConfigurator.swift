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
    
    var commands: [Command]? { [
        
        MinderStatLab(statMan: statMan, console: consoleView.console),
        MinderPlayed(statMan: statMan, console: consoleView.console),
        MinderOutputCSV(console: consoleView.console)
    
    ] }
    
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
    
}
