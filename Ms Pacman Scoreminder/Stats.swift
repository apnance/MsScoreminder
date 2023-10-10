//
//  Stats.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 11/1/21.
//

import UIKit
import APNUtil
import OrderedCollections

enum ScoreSortOrder { case date, high, low, avgDate, avgHigh, avgLow }

struct Stats {
    
    fileprivate var data = [ DateStringSimple : [Score] ]()
    fileprivate(set) var needsTally: Bool
    
    // singles
    fileprivate var scoresDateSorted            = [Score]()
    fileprivate var scoresHighSorted            = [Score]()
    fileprivate var scoresLowSorted             = [Score]()
    
    // averages
    fileprivate var averageDate: OrderedDictionary<Date, Score> = [:]
    
    fileprivate var avgScoresHighSorted         = [Score]()
    fileprivate var avgScoresLowSorted          = [Score]()
    
    fileprivate var dailies                     = [DailyStats]()
    
    var levelTally: [Int]!
    var highScore:  Score!
    var lowScore:   Score!
    var avgScore:   Score!
    var singleGamesCount  = 0
    var averagedGamesCount : Int { dailies.count }
    
    fileprivate var streaks: StreakSet?
    
    /// Returns a chronologically-sorted array of `Date`s in `simpleDate` format
    var dates: [Date] { data.keys.map{$0.simpleDate}.sorted() }
    
    init() {
        
        needsTally  = true
        data        = [String : [Score]]()
        
    }
    
}

extension StatManager {
    
    /// Returns the closest pervious averages Score to `from` `Date` or nil if
    /// from is the `Date` oldest available averaged `Score`
    func getNearestFutureAveragedScore(from: Date) -> Score? {
        
        if let dateIndex = stats.averageDate.index(forKey: from),
            dateIndex > 0 {
            
            return stats.averageDate.elements[dateIndex - 1].value /*EXIT*/
            
        }
        
        return nil /*EXIT*/
        
    }
    
    /// Returns the closest future averages Score to `from` `Date` or nil if
    /// from is the `Date` newest available averaged `Score`
    func getNearestPastAveragedScore(from: Date) -> Score? {
        
        if let dateIndex = stats.averageDate.index(forKey: from),
           dateIndex < stats.averageDate.elements.count - 1 {
            
            return stats.averageDate.elements[dateIndex + 1].value /*EXIT*/
            
        }
        
        return nil /*EXIT*/
        
    }
    
    func getScoreData() -> [DateStringSimple : [Score] ] { stats.data }
    
    /// Returns all `Score`s for the specified `DateStringSimple`
    /// - note: when starting with `Date` instead call `getScoresFor(_:Date)`
    func getScoresFor(_ date: DateStringSimple) -> [Score] { stats.data[date] ?? [] }
    
    /// Returns all `Score`s for the specified `Date`
    /// - note: When starting with `DateStringSimple` instead  call `getScoresFor(_:DateStringSimple)`
    func getScoresFor(_ date: Date) -> [Score] { getScoresFor(date.simple) }
    
    func setData(_ date: DateStringSimple, using: [Score]) {
        
        stats.data[date] = using
        
        if stats.data[date]?.count == 0 {
            
            stats.data.removeValue(forKey: date)
            
        }
        
        stats.needsTally = true
        
    }
    
    func getTotalGamesPlayed() -> Int { stats.singleGamesCount }
    
    func getScores(sortedBy: ScoreSortOrder) -> [Score] {
        
        switch sortedBy {
                
            // singles
            case .date:     return stats.scoresDateSorted
            case .high:     return stats.scoresHighSorted
            case .low:      return stats.scoresLowSorted
                
            // averages
            case .avgDate:  return stats.averageDate.values.elements  //* from OrderedDictionary
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
    func getDailyStatsSummary(forDate date: Date = Date()) -> DailyStatsCluster {
        
        var cluster = DailyStatsCluster()
        
        let simpleDate = date.simple
        
        for daily in stats.dailies {
            
            if daily.date.simple == simpleDate { cluster.requested = daily }
            
            if daily.areHigh { cluster.high = daily }
            
            if daily.areLow { cluster.low = daily }
            
        }
        
        return cluster
        
    }
    
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
        stats.averageDate.removeAll()
        
        dailies.sorted{ $0.date > $1.date }.forEach{ stats.averageDate[$0.date] = Score(date:    $0.date,
                                                                                        score:   $0.averageScore,
                                                                                        level:   $0.averageLevel,
                                                                                        averagedGameCount: $0.gamesPlayed) }
        
        stats.avgScoresHighSorted   = dailies.sorted{ $0.averageScore > $1.averageScore }.map{Score(date:   $0.date,
                                                                                                    score:  $0.averageScore,
                                                                                                    level:  $0.averageLevel,
                                                                                                    averagedGameCount: $0.gamesPlayed) }
        
        stats.avgScoresLowSorted    = stats.avgScoresHighSorted.reversed()
        
    }
    
    /// Returns `StreakSet` of current consecutive days played streak and longest consecutive days played.
    func getStreaks() -> StreakSet? { stats.streaks }
    
    func setStreaks(with dates: [DateStringSimple]) {
        
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
