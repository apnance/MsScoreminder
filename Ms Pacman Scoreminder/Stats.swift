//
//  Stats.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 11/1/21.
//

import UIKit
import APNUtil

//HERE...
// TODO: Clean Up - investigate moving various scores arrays below to OrderedDictionary for quicker lookup
import OrderedCollections

enum ScoreSortOrder { case date, high, low, avgDate, avgHigh, avgLow }

/// Return type of `getDailyStatsSummary(forDate:)`
typealias DailyStatCluster = (requested: DailyStats?, high: DailyStats?, low: DailyStats?)

struct Stats {
    
    fileprivate var data = [ DateString : [Score] ]()
    fileprivate(set) var needsTally: Bool
    
    // singles
    fileprivate var scoresDateSorted            = [Score]()         // { didSet { print(#function) } }
    fileprivate var scoresHighSorted            = [Score]()         // { didSet { print(#function) } }
    fileprivate var scoresLowSorted             = [Score]()         // { didSet { print(#function) } }
    
    // averages
    fileprivate var avgScoresDateSorted         = [Score]()         // { didSet { print(#function) } }
    fileprivate var avgScoresReverseDateSorted  = [Score]()         // { didSet { print(#function) } }
    fileprivate var avgScoresHighSorted         = [Score]()         // { didSet { print(#function) } }
    fileprivate var avgScoresLowSorted          = [Score]()         // { didSet { print(#function) } }
    
    fileprivate var dailies                     = [DailyStats]()    // { didSet { print(#function) } }
    
    var levelTally: [Int]!
    var highScore: Score!
    var lowScore: Score!
    var avgScore: Score!
    var gamesCount  = 0
    
    fileprivate var streaks: StreakSet?
    
    /// Returns a sorted array of Dates in simpleDate format
    var dates: [Date] { data.keys.map{$0.simpleDate}.sorted() }
    
    init() {
        
        needsTally  = true
        data        = [String : [Score]]()
        
        var orderedDictionary = OrderedDictionary<DateString, Score>()
        orderedDictionary.reverse()
    }
    
}

extension StatManager {
    
    func getNearestPastAveragedScore(from: Date) -> Score? {
        
        let fromSimple = from.simple.simpleDate
        
        for score in stats.avgScoresDateSorted {
            
            if score.date < fromSimple { return score /*EXIT*/ }
            
        }
        
        return nil /*EXIT*/
        
    }
    
    func getNearestFutureAveragedScore(from: Date) -> Score? {
        
        let fromSimple = from.simple.simpleDate
        
        for score in stats.avgScoresReverseDateSorted {
            
            if score.date > fromSimple { return score /*EXIT*/ }
            
        }
        
        return nil /*EXIT*/
        
    }
    
    func getScoreData() -> [DateString : [Score] ] { return stats.data }
    func getScoresFor(_ date: DateString) -> [Score] { stats.data[date] ?? [] }
    
    func setData(_ date: DateString, using: [Score]) {
        
        stats.data[date] = using
        
        if stats.data[date]?.count == 0 {
            
            stats.data.removeValue(forKey: date)
            
        }
        
        stats.needsTally = true
        
    }
    
    func getTotalGamesPlayed() -> Int { stats.gamesCount }
    
    func getScores(sortedBy: ScoreSortOrder) -> [Score] {
        
        switch sortedBy {
                
            // singles
            case .date:     return stats.scoresDateSorted
            case .high:     return stats.scoresHighSorted
            case .low:      return stats.scoresLowSorted
                
            // averages
            case .avgDate:  return stats.avgScoresDateSorted
            case .avgHigh:  return stats.avgScoresHighSorted
            case .avgLow:   return stats.avgScoresLowSorted
                
        }
        
    }
    
    func setScores(_ scores: [Score]) {
        
        stats.scoresDateSorted          = scores.sorted{ $0.date > $1.date }
        stats.scoresHighSorted          = scores.sorted{ $0.score > $1.score }
        stats.scoresLowSorted           = scores.sorted{ $0.score < $1.score }
        
    }
    
    /// Returns `[DailyStats]` containing the highest average score, lowest average score,
    /// and today's average score(if available - i.e. more than 1 game played today).
    func getDailyStatsSummary(forDate date: Date = Date()) -> DailyStatCluster {
        
        var cluster: DailyStatCluster = (nil, nil, nil)
        
        let simpleDate = date.simple
        
        for daily in stats.dailies {
            
            if daily.date.simple == simpleDate { cluster.requested = daily }
            
            if daily.areLow { cluster.high = daily }
            
            if daily.areHigh { cluster.low = daily }
            
        }
        
        return cluster
        
    }
    
    //     TODO: Clean Up - BUG
    //bug: fix bug causing average atomic score UI to show percentiles computed against single scores not average scores.
    
    /// Returns the `DailyStats` for the nearest past date.
    func getPreviousDaily(forDate date: Date) -> DailyStats? {
        
        guard let previousDate = getNearestPastAveragedScore(from: date)?.date else { return nil /*EXIT*/ }
            
            return getDaily(for: previousDate)
        
    }
    
    /// Returns the `DailyStats` for the specified `Date` or null if none found for that `Date`.
    func getDaily(for date: Date) -> DailyStats? {
        
        let forSimple = date.simple
        
        for daily in stats.dailies {
            
            if daily.date.simple == forSimple { return daily /*EXIT*/ }
            
        }
        
        return nil
        
    }
    
    func setDailys(_ dailies: [DailyStats]) {
        
        stats.dailies               = dailies
        
        stats.avgScoresDateSorted   = dailies.sorted{ $0.date > $1.date }.map{ Score(date: $0.date,
                                                                                     score: $0.averageScore,
                                                                                     level: $0.averageLevel,
                                                                                     averagedGameCount: $0.gamesPlayed) }
        
        stats.avgScoresReverseDateSorted = stats.avgScoresDateSorted.reversed()
        
        stats.avgScoresHighSorted   = dailies.sorted{ $0.averageScore > $1.averageScore }.map{Score(date:   $0.date,
                                                                                                    score:  $0.averageScore,
                                                                                                    level:  $0.averageLevel,
                                                                                                    averagedGameCount: $0.gamesPlayed) }
        
        stats.avgScoresLowSorted    = dailies.sorted{ $0.averageScore < $1.averageScore }.map{Score(date: $0.date,
                                                                                                    score: $0.averageScore,
                                                                                                    level: $0.averageLevel,
                                                                                                    averagedGameCount: $0.gamesPlayed) }
        
    }
    
    /// Returns `StreakSet` of current consecutive days played streak and longest consecutive days played.
    func getStreaks() -> StreakSet? { stats.streaks }
    
    func setStreaks(with dates: [DateString]) {
        
        // This method is very inefecient, call only if there is no current streak
        if stats.streaks?.recent.isCurrent ?? false { return /*EXIT*/ }
        
        let dates = dates.map{$0.simpleDate}.sorted{$0 < $1}
        
        var current = PlayStreak()
        var longest = PlayStreak()
        
        for date in dates {
            
            current = current.extend(with: date)
            longest = longest.length <= current.length ? current : longest
            
        }
        
        stats.streaks = (current, longest)
        
    }
    
    func clearNeedsTally() { stats.needsTally = false }
    
}
