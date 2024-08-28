//
//  StatLab.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/16/23.
//

import Foundation

struct StatLab {
    
    /// Array of all `Score`s to analyze
    private static var scores = [Score]()
    
    /// Max level number contained in scores
    private static var maxLevel = 0
    
    /// Level-num to `[Score]` lookup
    private static var levelToScore = [Int : [Score]]()
    
    /// Lookup the range of scores per `Level`
    private static var levelToScoreRange = [Int : (low: Int, high: Int)]()
    
    /// Process `Score`s generating lookup dictionaries for analytical test methods
    private static func process(_ scores: [Score]) {
        
        Self.scores = scores
        
        // Sort scores into levels
        for score in scores {
            
            // Level
            let level = score.level.num
            maxLevel = max(maxLevel, level)
            
            if levelToScore[level].isNil {
                
                // Initialize
                levelToScore[level] = [score]
                levelToScoreRange[level] = (score.score, score.score)
                
            } else {
                
                // Load
                // l2score
                levelToScore[level]?.append(score)
                
                // l2range
                var (low,high) = levelToScoreRange[level]!
                low = min(score.score, low)
                high = max(score.score, high)
                levelToScoreRange[level] = (low, high)
                
            }
            
        }
        
    }
    
    /// Perform expensive/experimental analyses on `Score` data
    /// - Returns: Results of analysis as `String`
    static func analyze(_ scores: [Score]) -> String {
        
        process(scores)
        
        var results = ""
        
        let runTime = ContinuousClock().measure {
            
            results += """
                        \(calculateAverageLevelScores())
                        
                        \(calculateLevelScoreRanges())
                        
                        \(calcGamesPerLevel())
                        
                        \(displayOptimalityTable())
                        
                        """
            
        }
        
        results = """
                    ------------------------------------
                    \(results)
                    ------------------------------------
                    StatLab Run Time: \(runTime)
                    ------------------------------------
                    """
        
        print(results)
        
        return results
        
    }
    
    static func displayOptimalityTable() -> String {
        
        var results = """
                        [Optimality Table]
                        """
        
        for level in 0...maxLevel {
            
            let level           = Level.get(level)
            let levelName       = level.name
            
            let optimality      = level.optimalScore
            let optimalityCum   = level.optimalScoreCummulative
            
            results += "\n  \(levelName): \(optimality) / \(optimalityCum)"
            
        }
        
        return results
        
    }
    
    static func calcGamesPerLevel() -> String {
        
        var results = """
                        [Games Per Level]
                        """
        
        for level in 0...maxLevel {
            
            let levelName = Level.get(level).name
            let gameCount = levelToScore[level]?.count ?? 0
            
            results += "\n  \(levelName): \(gameCount)"
            
        }
        
        results += """
                      
                      _____________________
                      Total: \(scores.count)
                    """
        
        return results
        
    }
    
    static func calculateAverageLevelScores() -> String {
        
        var results = """
                        [Average Score by Level]
                        """
        
        for level in levelToScore.keys.sorted() {
            
            if let scores = levelToScore[level] {
                
                var runningScoreTotal = 0
                
                for score in scores {
                    
                    runningScoreTotal += score.score
                    
                    
                }
                let avgScore = runningScoreTotal / scores.count
                
                results += "\n  \(Level.get(level).name): \(avgScore)"
                
            }
            
        }
        
        return results
        
    }
    
    static func calculateLevelScoreRanges() -> String {
        
        var results = """
                        [Score Ranges by Level]
                        """
        
        for levelNum in levelToScoreRange.keys.sorted() {
            
            if let (low,high) = levelToScoreRange[levelNum] {
                
                results += "\n  \(Level.get(levelNum).name): \(low)...\(high)"
                
            }
            
        }
        
        return results
        
    }
    
    
}
