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
    
    @discardableResult init(statManager: StatManager) {
        
        self.statMan        = statManager
        
        load()
        
    }
    
    weak private var statMan: StatManager!
    
   var consoleView: ConsoleView { Console.screen }
    
    var commands: [Command]? { [
        
        MinderStatLab(statMan: statMan),
        MinderPlayed(statMan: statMan),
        MinderCSV(statMan: statMan)
        
    ] }
    
    var configs: ConsoleViewConfigs? {
        
        var configs = ConsoleViewConfigs()
        
        configs.fgColorPrompt                   = UIColor.darkPink
        configs.fgColorCommandLine              = UIColor.darkPink
        configs.fgColorScreenInput              = UIColor.orange
        configs.fgColorScreenOutput             = UIColor.banana
        configs.fgColorScreenOutputNote         = UIColor.msBlue
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
        
        configs.aboutScreen =   """
                                Ms.
                                Score-
                                minder
                                \("v\(Bundle.appVersion)")
                                """.fontify(.small)
        
        return configs
        
    }
    
}
