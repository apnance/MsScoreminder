//
//  Stats.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 11/1/21.
//

import APNUtils

enum ScoreSortOrder { case date, high, low }

struct Stats {
    
    fileprivate var data = [ DateString : [Score] ]()
    fileprivate(set) var needsTally: Bool
    
    fileprivate var scoresDateSorted    = [Score]()
    fileprivate var scoresHighSorted    = [Score]()
    fileprivate var scoresLowSorted     = [Score]()
    
    fileprivate var dailyStats          = [DailyStats]()
    
    var levelTally: [Int]!
    
    var highScore: Score!
    var gamesCount  = 0
    
    fileprivate var streaks: StreakSet?
    
    var dates: [DateString] { Array(data.keys) }
    
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
            
            case .date: return stats.scoresDateSorted
                
            case .high: return stats.scoresHighSorted
                
            case .low: return stats.scoresLowSorted
            
        }
        
    }
    
    func setScores(_ scores: [Score]) {
        
        stats.scoresDateSorted    = scores.sorted{ $0.date > $1.date }
        stats.scoresHighSorted    = scores.sorted{ $0.score > $1.score }
        stats.scoresLowSorted     = scores.sorted{ $0.score < $1.score }
        
    }
    
    /// Returns `[DailyStatss]` containing the highest average score, lowest average score,
    /// and today's stats(if available).
    func getDailyStats(_ date: DateString) -> [DailyStats] {
        
        getDailyStats(date.simpleDate)
        
    }

    /// Returns `[DailyStatss]` containing the highest average score, lowest average score,
    /// and today's stats(if available).
    func getDailyStats(_ date: Date) -> [DailyStats] {
        
        var returnStats = [DailyStats]()
        
        for daily in stats.dailyStats {
            
            if daily.areToday || daily.areLow || daily.areHigh {
                
                returnStats.append(daily)
                
            }
            
        }
        
        return returnStats.sorted{ $0.date > $1.date }
        
    }
    
    func setDailys(_ dailies: [DailyStats]) { stats.dailyStats = dailies }
    
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
