//
//  DailyStats.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/29/21.
//

import Foundation

struct DailyStats {
    
    var date: Date = Date()
    var rank: (Int, Int) = (-123,-1234)
    var averageScore: Int = -12345
    var gameCount: Int = -12345
    
}

extension DailyStats: CustomStringConvertible {
    
    var description: String {
        
        "\(date.simple) - rank(\(rank.0)/\(rank.1)) - avg score: \(averageScore) - game count: \(gameCount)"
        
    }
    
}
