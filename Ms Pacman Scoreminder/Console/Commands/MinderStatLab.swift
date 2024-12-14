//
//  MinderStatLab.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 9/29/24.
//

import ConsoleView

/// Echoes various interesting stats to `screen`
@available(iOS 15, *)
struct MinderStatLab: Command {
    
    var statMan: StatManager
    
    // - MARK: Command Requirements
    var commandToken    = Configs.Console.Commands.StatLab.token
    
    var isGreedy        = false
    
    var category        = Configs.Console.Commands.category
    
    var helpText        = Configs.Console.Commands.StatLab.helpText
    
    func process(_ args: [String]?) -> CommandOutput {
        
        CommandOutput.output(statMan.runStatLab())
        
    }
}

