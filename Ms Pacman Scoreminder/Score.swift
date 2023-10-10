//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import UIKit
import APNUtil
import APNGraph

struct Score: Hashable {
    
    static var levelCount = 15
    
    /// Returns a `Score` initialized with today's date, score 0, and level 0
    static var zero: Score { Score(date: Date(), score: 0, level: 0) }
    
    var date: Date
    var score: Int
    var level: Level
    
    /// The number of game scores included in average score.
    /// - note: Default value is 1 and indicates an unaveraged `Score`.
    private(set) var averagedGameCount: Int
    
    /// Does this `Score` represent an
    var isAveraged: Bool { averagedGameCount > 1 }
    var isSingle: Bool { averagedGameCount == 1 }
        
    var displayScore: String { score.delimited }
    
    var optimality: Double { Double(score) / Double(level.optimalScoreCummulative) }
    
    init(date: Date,
         score: Int,
         level: Int,
         averagedGameCount: Int = 1) {
        
        self.date               = date
        self.score              = score
        self.level              = Level.get(level)
        self.averagedGameCount  = averagedGameCount
        
    }
    
    /// - Returns: Random Score, with randomized date, score, and level.
    /// - parameters:
    ///     - allowInvalidScores: flag indicating whether invalid (i.e. non-multiple of 10) scores should allowed in output.
    /// - note: useful for testing
    /// - note: return value is not always valid(i.e. isn't always a multiple of 10 as valid scores should)
    /// - note: generated date values range from 1/1/18 to 12/28/23.  The day values range from 1-28 to avoid leap-year considerations.
    static func random(allowInvalidScores: Bool = true) -> Score {
        
        let maxYearsPast    = 5
        let maxDaysPast     = maxYearsPast * 365
        let randomShift     = (0...maxDaysPast).randomElement()!
        let randomDate      = Date().shiftedBy(-randomShift)
        
        let randomLevel     = Int.random(min:0, max: 11)
        
        var randomScore     = Int.random(min: randomLevel * 2500, 
                                         max: (randomLevel + 1) * 14600)
        
        if !allowInvalidScores { randomScore /= 10; randomScore *= 10 }
        
        
        return Score(date: randomDate,
                     score: randomScore,
                     level: randomLevel)
    }
    
}

// - MARK: CustomStringConvertible
extension Score: CustomStringConvertible {
    
    var description: String {
        
        "\(date.simple)|\(score.delimited)|\(level.abbr)"
        
    }
    
    var csv: String { "\(date.simple),\(score),\(level.num)\n" }
    
}

// - MARK: Equatable
extension Score: Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        (lhs.score, lhs.level) == (rhs.score, rhs.level)
        
    }
    
}

// - MARK: Graphable
extension Score : APNGraphable {
    
    typealias X = Date
    typealias Y = Int
    
    var x: X {
        get { self.date }
        set { self.date = newValue }
    }
    
    var y: Y {
        get { self.score }
        set { self.score = newValue }
    }
    
    var pointColor: UIColor { level.colorLight }
    var pointBorderColor: UIColor { .black.pointEightAlpha }
    var pointImageName: String? { "ms_graph_icon_\(level.num)" }
    
}
