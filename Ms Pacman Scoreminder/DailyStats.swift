//
//  DailyStats.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/29/21.
//

import Foundation

/// Data model describing aggregate scores for a given day.
struct DailyStats {
    
    /// `Date` for which score data was collected.
    var date: Date = Date()
    
    /// Rank of today's average against all other recorded average scores.
    var rank: (Int, Int)        = (-123,-1234)
    
    /// The average score of all `Score`s for `date`
    var averageScore: Int       = -12345
    var averageLevel: Int       = -123
    
    /// Number of `Score`s recorded for `date` (i.e. the number games played on `date`)
    var gamesPlayed: Int        = -12345
    
    /// An array of the count of numer of games that concluded on each level.
    var levelsReached           = Array(repeating: 0, count: Score.levelCount)
    
    /// Indicates if this `DailyStats` `averageScore` is the lowest recorded.
    var areLow: Bool {      rank.0 == rank.1 }
    
    /// Indicates if this `DailyStats` `averageScore` is the highest recorded.
    var areHigh: Bool {     rank.0 == 1 }
    
    /// Flag indicating if these `DailyStats` are for today
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
