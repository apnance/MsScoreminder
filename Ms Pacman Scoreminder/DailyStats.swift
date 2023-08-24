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
    
    /// The average of the last 7 daily scores.  Scores are averaged chronological
    /// but necessarily consecuitvely as such this property doesn't necessarily
    /// reflect the average of the last seven days. It is the average of the last seven recorded dailies.
    /// - e.g. if the last daily stats are from
    var sevenDayAverage: Int    = -12345
    
    /// The average level reached for games played on `date`
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
