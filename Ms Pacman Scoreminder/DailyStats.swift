//
//  DailyStats.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/29/21.
//

import Foundation

/// Data model describing aggregate scores for a given day.
struct DailyStats {
    
    var date: Date = Date()
    var rank: (Int, Int)    = (-123,-1234)
    var averageScore: Int   = -12345
    var averageLevel: Int   = -123
    var gamesPlayed: Int    = -12345
    var levelsReached       = Array(repeating: 0, count: Score.levelCount)
    
    var areLow: Bool {      rank.0 == rank.1 }
    var areHigh: Bool {     rank.0 == 1 }
    var areToday: Bool {    date.simple == Date().simple }
    
}

extension DailyStats: Equatable, Comparable {
    
    static func == (lhs: DailyStats, rhs: DailyStats) -> Bool {
        
        lhs.date.simple == rhs.date.simple
        
    }
    
    static func < (lhs: DailyStats, rhs: DailyStats) -> Bool {
        
        lhs.averageScore < rhs.averageScore
        
    }
    
}

extension DailyStats: CustomStringConvertible {
    
    var description: String {
        
        "\(date.simple) - rank: \(rank.0)/\(rank.1) - avg score: \(averageScore) - avg level: \(averageLevel) - game count: \(gamesPlayed)"
        
    }
    
}
