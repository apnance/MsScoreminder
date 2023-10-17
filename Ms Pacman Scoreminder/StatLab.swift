//
//  StatLab.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/16/23.
//

import Foundation

struct StatLab {
    
    private static var shouldAnalyze = false
    private static var runCount = 1
    
    static func analyze(_ scores: [Score]) {
        
        assert(runCount <= 1,
               "Statlab.analyze should only be called once(run count:\(runCount)")
        
        guard shouldAnalyze else { return /*EXIT*/ }
        shouldAnalyze = false
        
        calculateAverageLevelScores(scores)
        
        calculateLevelScoreRanges(scores)
        
    }
    
    static func calculateAverageLevelScores(_ scores: [Score]) {
        
        var levelSorted = [Int : [Score]]()
        
        // Sort scores into levels
        for score in scores {
            
            if levelSorted[score.level.num].isNil {
                
                levelSorted[score.level.num] = [score]
                
            } else {
                
                levelSorted[score.level.num]?.append(score)
                
            }
            
        }
        
        print("Average Score By Level:")
        for key in levelSorted.keys.sorted() {
            
            if let scores = levelSorted[key] {
                
                var runningScoreTotal = 0
                
                for score in scores {
                    
                    runningScoreTotal += score.score
                    
                    
                }
                let avgScore = runningScoreTotal / scores.count
                print("\(Level.get(key).name): \(avgScore)")
                
            }
            
        }
        
    }
    
    static func calculateLevelScoreRanges(_ scores: [Score]) {
        
        var levelSorted = [Int : (low: Int, high: Int)]()
        
        // Sort scores into levels
        for score in scores {
            
            if levelSorted[score.level.num].isNil {
                
                levelSorted[score.level.num] = (score.score, score.score)
                
            } else {
                
                var (low,high) = levelSorted[score.level.num]!
                
                low = min(score.score, low)
                high = max(score.score, high)
                
                
                levelSorted[score.level.num] = (low, high)
                
            }
            
        }
        
        print("\n---\nScore Ranges By Level:")
        for key in levelSorted.keys.sorted() {
            
            if let (low,high) = levelSorted[key] {
                
                print("\(Level.get(key).name): \(low)...\(high)")
                
            }
            
        }
        
    }
    
    
}
