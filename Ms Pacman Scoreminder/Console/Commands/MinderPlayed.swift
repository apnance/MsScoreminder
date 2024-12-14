//
//  MinderPlayed.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 9/29/24.
//

import Foundation

import ConsoleView

/// Echoes a list of stats summarizing all games played.
@available(iOS 15, *)
struct MinderPlayed: Command {
    
    var statMan: StatManager
    
    // - MARK: Command Requirements
    var commandToken    = Configs.Console.Commands.Played.token
    
    var isGreedy        = false
    
    var category        = Configs.Console.Commands.category
    
    var helpText        = Configs.Console.Commands.Played.helpText
    
    func process(_ args: [String]?) -> CommandOutput {
        
        var arg1 = args.elementNum(0)
        
        // Today?
        arg1 = (arg1.lowercased() == "today") ? Date().simple : arg1
        
        if let date = arg1.simpleDateMaybe {
            
            return CommandOutput.output(statMan.played(date))
            
        } else {
            
            return CommandOutput.output(statMan.played())
            
        }
        
    }
}

