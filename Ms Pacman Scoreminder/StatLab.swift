//
//  StatLab.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/16/23.
//

import APNUtil

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
        
        var data = buildDataArray()
        
        for level in 0...maxLevel {
            
            let level           = Level.get(level)
            let levelName       = level.name
            let optimality      = level.optimalScore
            let optimalityCum   = level.optimalScoreCummulative
            
            data[level.num].append(levelName)
            data[level.num].append(optimality.description)
            data[level.num].append(optimalityCum.description)
            
        }
        
        return buildReport(data:    data,
                           headers: ["Level", "Lvl Opt", "Cum. Opt",],
                           title:   "Optimality Table")
        
    }
    
    static func calcGamesPerLevel() -> String {
        
        var data = buildDataArray()
        
        for level in 0...maxLevel {
            
            
            data[level].append(Level.get(level).name)
            
            let gameCount = levelToScore[level]?.count ?? 0
            data[level].append(gameCount.description)
            
        }
        
        data.append(["", ""])
        data.append(["Total", "\(scores.count)"])
        
        return buildReport(data:    data,
                           headers: ["Level", "Games Reached"],
                           title:   "Games Per Level")
        
    }
    
    static func calculateAverageLevelScores() -> String {
        
        var data = buildDataArray()
        
        for level in levelToScore.keys.sorted() {
            
            if let scores = levelToScore[level] {
                
                var runningScoreTotal = 0
                
                for score in scores {
                    
                    runningScoreTotal += score.score
                    
                    
                }
                let avgScore = runningScoreTotal / scores.count
                
                
                data[level].append(Level.get(level).name)
                data[level].append(avgScore.description)
                
            }
            
        }
        
        return buildReport(data:    data,
                           headers: ["Level", "Avg. Score"],
                           title:   "Average Score by Level")
        
    }
    
    static func calculateLevelScoreRanges() -> String {
        
        var data = buildDataArray()
        
        for levelNum in levelToScoreRange.keys.sorted() {
            
            if let (low,high) = levelToScoreRange[levelNum] {
                
                data[levelNum].append(Level.get(levelNum).name)
                data[levelNum].append("\(low)...\(high)")
                
            }
            
        }
        
        return buildReport(data:    data,
                           headers: ["Level", "Low...High"],
                           title:   "Score Ranges by Level")
        
    }
    
    
}

// - MARK: Utilities
extension StatLab {
    
    private static func buildReport(data: [[String]], headers: [String], title: String) -> String {
        
        Report.columnateAutoWidth(data,
                                  headers:headers,
                                  title: title.uppercased(),
                                  dataPadType: .right,
                                  showSeparators: false)
        
    }
    
    private static func buildDataArray(withCount count: Int = maxLevel + 1) -> [[String]] {
        
        Array(repeating:[String](), count: count)
        
    }
    
}
