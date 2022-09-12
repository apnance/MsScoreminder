//
//  Stats.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 11/1/21.
//

import APNUtils

enum ScoreSortOrder { case date, high, low, avgDate, avgHigh, avgLow }

struct Stats {
    
    fileprivate var data = [ DateString : [Score] ]()
    fileprivate(set) var needsTally: Bool
    
    // singles
    fileprivate var scoresDateSorted    = [Score]()
    fileprivate var scoresHighSorted    = [Score]()
    fileprivate var scoresLowSorted     = [Score]()
    
    // averages
    fileprivate var avgScoresDateSorted = [Score]()
    fileprivate var avgScoresHighSorted = [Score]()
    fileprivate var avgScoresLowSorted  = [Score]()
    
    fileprivate var dailies             = [DailyStats]()
    fileprivate var dailiesDateSorted: [DailyStats] { dailies.sorted{$0.date > $1.date } }
    
    var levelTally: [Int]!
    var highScore: Score!
    var lowScore: Score!
    var avgScore: Score!
    var gamesCount  = 0
    
    fileprivate var streaks: StreakSet?
    
    /// Returns a sorted array of Dates in simpleDate format
    var dates: [Date] { data.keys.map{$0.simpleDate}.sorted() }
    
    init() {
        
        needsTally = true
        data = [String : [Score]]()
        
    }
    
}

extension StatManager {
    
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
        
        stats.scoresDateSorted    = scores.sorted{ $0.date > $1.date }
        stats.scoresHighSorted    = scores.sorted{ $0.score > $1.score }
        stats.scoresLowSorted     = scores.sorted{ $0.score < $1.score }
        
    }
    
    /// Returns `[DailyStats]` containing the highest average score, lowest average score,
    /// and today's average score(if available - i.e. more than 1 game played today).
    func getDailyStatsSummary() -> [DailyStats] {
        
        var returnStats = [DailyStats]()
        
        for daily in stats.dailies {
            
            if daily.areToday || daily.areLow || daily.areHigh {
                
                returnStats.append(daily)
                
            }
            
        }
        
        return returnStats.sorted{ $0.date > $1.date }
        
    }

//    HERE!!!
//     TODO: Clean Up - BUG
    //bug: fix bug causing average atomic score UI to show percentiles computed against single scores not average scores.
    
    /// Returns the second most recent `DailyStats`, akin to concept of "yesterday's" stats.
    func getPreviousDaily() -> DailyStats? {
        
        stats.dailiesDateSorted.second
        
    }
    
    /// Returns the `DailyStats` for the specified `Date` or null if none found for that `Date`.
    func getDaily(for date: Date) -> DailyStats? {
        
        for daily in stats.dailies {
            
            if daily.areToday { return daily /*EXIT*/ }
                
        }
        
        return nil
        
    }
    
    func setDailys(_ dailies: [DailyStats]) {
        
        stats.dailies               = dailies
        
        stats.avgScoresDateSorted   = dailies.sorted{ $0.date > $1.date }.map{ Score(date: $0.date,
                                                                                     score: $0.averageScore,
                                                                                     level: $0.averageLevel,
                                                                                     averagedGameCount: $0.gamesPlayed) }
        
        stats.avgScoresHighSorted   = dailies.sorted{ $0.averageScore > $1.averageScore }.map{Score(date: $0.date,
                                                                                                    score: $0.averageScore,
                                                                                                    level: $0.averageLevel,
                                                                                                    averagedGameCount: $0.gamesPlayed) }
        
        stats.avgScoresLowSorted    = dailies.sorted{ $0.averageScore < $1.averageScore }.map{Score(date: $0.date,
                                                                                                    score: $0.averageScore,
                                                                                                    level: $0.averageLevel,
                                                                                                    averagedGameCount: $0.gamesPlayed) }
        
    }
    
    /// Returns `StreakSet` of current consecutive days played streak and longest consecutive days played.
    func getStreaks() -> StreakSet? { stats.streaks }
    
    //TODO: add streaks to email
    
    func setStreaks(with dates: [DateString]) {
        
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
