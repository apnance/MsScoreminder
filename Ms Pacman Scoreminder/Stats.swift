//
//  Stats.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 11/1/21.
//

import APNUtils

enum ScoreSortOrder { case date, high, low }

struct Stats{
    
    fileprivate var data = [ DateString : [Score] ]()
    fileprivate(set) var needsTally: Bool
    
    fileprivate var scoresDateSorted    = [Score]()
    fileprivate var scoresHighSorted    = [Score]()
    fileprivate var scoresLowSorted     = [Score]()
    
    fileprivate(set) var dailyStats          = [DailyStats]()
    
    var levelTally: [Int]!

    
    var highScore: Score!
    var gamesCount  = 0
    
    var dates: [DateString] { Array(data.keys) }
    
    init() {
        
        needsTally = true
        data = [String : [Score]]()
        
    }
    
    // TODO: Clean Up - rename getDataFor -> getScoresFor
    func getData() -> [DateString : [Score] ] { return data }
    func getDataFor(_ date: DateString) -> [Score] { data[date] ?? [] }


    mutating func setData(_ date: DateString, using: [Score]) {

        data[date] = using

        if data[date]?.count == 0 {

            data.removeValue(forKey: date)

        }

        needsTally = true

    }

    func getScores(sortedBy: ScoreSortOrder) -> [Score] {

        switch sortedBy {

        case .date: return scoresDateSorted

        case .high: return scoresHighSorted

        case .low: return scoresLowSorted

        }

    }

    mutating func setScores(_ scores: [Score]) {
        
        scoresDateSorted    = scores.sorted{ $0.date > $1.date }
        scoresHighSorted    = scores.sorted{ $0.score > $1.score }
        scoresLowSorted     = scores.sorted{ $0.score < $1.score }
        
    }
    
    
    mutating func setDailys(_ dailies: [DailyStats]) { dailyStats = dailies }
    
    mutating func clearNeedsTally() { needsTally = false }
    
}

//extension ScoreManager {
//
//    // TODO: Clean Up - rename getDataFor -> getScoresFor
//    func getData() -> [DateString : [Score] ] { return stats.data }
//    func getDataFor(_ date: DateString) -> [Score] { stats.data[date] ?? [] }
//
//
//    func setData(_ date: DateString, using: [Score]) {
//
//        stats.data[date] = using
//
//        if stats.data[date]?.count == 0 {
//
//            stats.data.removeValue(forKey: date)
//
//        }
//
//        stats.needsTally = true
//
//    }
//
//    func getScores(sortedBy: ScoreSortOrder) -> [Score] {
//
//        switch sortedBy {
//
//        case .date: return stats.scoresDateSorted
//
//        case .high: return stats.scoresHighSorted
//
//        case .low: return stats.scoresLowSorted
//
//        }
//
//    }
//
//    func setScores(_ scores: [Score]) {
//
//        stats.scoresDateSorted    = scores.sorted{ $0.date > $1.date }
//        stats.scoresHighSorted    = scores.sorted{ $0.score > $1.score }
//        stats.scoresLowSorted     = scores.sorted{ $0.score < $1.score }
//
//    }
//
//
//    func setDailys(_ dailies: [DailyStats]) { stats.dailyStats = dailies }
//
//    func clearNeedsTally() { stats.needsTally = false }
//
//}
