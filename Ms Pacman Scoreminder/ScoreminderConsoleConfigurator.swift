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
        
        self._consoleView   = consoleView
        self.statMan        = statManager
        
        load()
        
    }
    
    weak private var _consoleView: ConsoleView!
    weak private var statMan: StatManager!
    
    var consoleView: ConsoleView { _consoleView }
    
    var commands: [Command]? { [
        
        MinderStatLab(statMan: statMan, console: consoleView.console),
        MinderPlayed(statMan: statMan, console: consoleView.console),
        MinderCSV(statMan: statMan, console: consoleView.console)
        
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
        
        configs.aboutScreen =   """
                                Ms.
                                Score-
                                minder
                                \("v\(Bundle.appVersion)")
                                """.fontify(.small)
        
        return configs
        
    }
    
}
