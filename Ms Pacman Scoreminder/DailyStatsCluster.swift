//
//  DailyStatsCluster.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 2/7/23.
//

import Foundation

/// Return type of `getDailyStatsSummary(forDate:)`
struct DailyStatsCluster {

    private var currentStatIndex = -1
    
    var requested: DailyStats?
    var high: DailyStats?
    var low: DailyStats?
    
    var isEmpty: Bool { stats.count == 0 }
    
    private var stats = [DailyStats]()
    
    /// Cycles through the available `DailyStats` returning the next in sequence
    /// or first in sequence if the end of sequence has been reached.
    mutating func getNext() -> DailyStats {
        
        buildStats()
        
        currentStatIndex += 1
        
        if currentStatIndex > stats.lastUsableIndex { currentStatIndex = 0}
        
        return stats[currentStatIndex]
        
    }
    
    mutating private func buildStats() {
        
        if stats.count != 0 { return /*EXIT - Build only once!*/ }
        
        if let requested    = requested { stats.append(requested) }
        if let high         = high      { stats.append(high) }
        if let low          = low       { stats.append(low) }
        
    }
    
}
