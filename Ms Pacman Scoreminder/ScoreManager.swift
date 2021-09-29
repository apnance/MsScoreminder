//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

struct ScoreManager : Codable {

    private var gamesCount = 0
    private var highScore: Score?
    
    // Array for tracking number of games played to each level.
    private var levelTally: [Int]?
    
    private var data: [ String : [Score] ]
    private var scores: [Score] {
        
        var scoreArray = [Score]()
        
        for dayScores in data.values {
            
            for score in dayScores {
                
                scoreArray.append(score)
                
            }
            
        }
        
        return scoreArray
        
    }
    
    private var scoresSorted: [Score] {
        
        scores.sorted{ $0.date > $1.date }
        
    }
    
    init() {
        
        data = [String : [Score]]()
                
    }
    
    // Adds or updates score in the data hash
    mutating func set(_ score: Score) {
        
        guard var currData = data[score.date.simple]
        else {
            
            self.data[score.date.simple] = [score]
            
            tallyStats()
            
            return /*EXIT*/
            
        }
        
        for i in 0..<currData.count {
            
            if currData[i].score == score.score {
                
                currData[i] = score
                
                self.data[score.date.simple] = currData
            
                tallyStats()
                
                return /*EXIT*/
                
            }
            
        }
        
        currData.append(score)
        
        self.data[score.date.simple] = currData
        
        tallyStats()
        
    }
    
    mutating func remove(_ score: Score) {
        
        guard var data = data[score.date.simple]
        else { return /*EXIT*/ }
        
        for i in 0..<data.count {
            
            if data[i].score == score.score {
                
                data.remove(at: i)
                self.data[score.date.simple] = data
                
                return /*EXIT*/
                
            }
            
        }
        
        tallyStats()
        
    }
    
    mutating func tallyStats() {

        gamesCount = 0
                
        levelTally = Array(repeating: 0, count: Score.levels.count)
        
        var highScore: Score?
        var high = 0
        
        for dayScores in data.values {
                        
            for score in dayScores {
            
                // General Stats
                gamesCount += 1
                levelTally![score.level] += 1
                
                // High Score
                if score.score > high {
                    
                    high = score.score
                    highScore = score
                    
                }
                
            }
            
        }
        
        self.highScore = highScore
            
    }
    
    mutating func getMoneySpent() -> String {
        
        let money       = getGamesCount() * 25
        var moneyText   = "$\(money)"
        
        moneyText.insert(".", at: moneyText.index(moneyText.endIndex, offsetBy: -2))
        
        return moneyText
        
    }
    
    mutating func getGamesCount() -> Int {
        
        if gamesCount == 0 { tallyStats() }
        
        return gamesCount
        
    }
    
    mutating func getHighscore() -> Score? {

        if highScore == nil { tallyStats() }
        
        return highScore
    
    }
    
    func getLast(_ count: Int) -> [Score] {
        
        let end = min(count, gamesCount) - 1
        
        if end < 0 { return [] }
        
        return scoresSorted.sub(start: 0, end: end)
        
    }
    
    func getScores(forDateString date: String) -> [Score] {
        
        data[date] ?? [Score]()
        
    }
    
    // Converts data to [["Date", "Score", "Level"]]
    func getScoreArray() -> (score: [[String]], headers: [String]) {
        
        var scoreArray = [[String]]()
                
        let scores = scoresSorted
        
        for score in scores {
            
            scoreArray.append([score.date.simple,
                               score.score.description,
                               score.level.description])
            
        }
        
        return (scoreArray, ["Date", "Score", "Level"])
        
    }
    
    func getScoreReport(forDateString date: String = Date().simple) -> String {
        
        let rawData = getScores(forDateString: date)
        
        var data = [[String]]()
        
        for datum in rawData {
            
            data.append([datum.date.simple, datum.displayScore, datum.levelString])
            
        }
        
        var report = ""
        let headers = ["Date", "Score", "Level"]
        if data.count > 0 {
            
            report = Report.columnateAutoWidth(data, headers: headers, title: "Scores for \(Date().simple)")
            
        }
        
        return report
        
    }
    
    
    mutating func getLevelReport() -> String {
        
        var rowData = [[String]]()
        
        if levelTally == nil { tallyStats() }
        
        for (level, count) in levelTally!.enumerated() {
            
            let percent = ((count.double / gamesCount.double) * 100).roundTo(1)
            rowData.append([Score.levelString[level], "\(count)", "\(percent)%"])
            
        }
        
        var report = ""
        let headers = ["Level", "Count", "Percent"]
        
        if rowData.count > 0 {
            
            report = Report.columnateAutoWidth(rowData, headers: headers, title: "Levels Reached")
            
        }
        
        return report
        
    }
        
}

extension ScoreManager: CustomStringConvertible {
    
    var description: String {
        var i = 0
        var descr = ""
        
        for scores in data.values {
            
            descr += "\(i) : \(scores)\n"
            
            i += 1
            
        }
        
        return descr
        
    }
    
}

extension ScoreManager {
    
    static func importData() -> ScoreManager {
        
        var scoreMan = ScoreManager()
        let rawData = HistoricScores.data.split(separator: "\n")
        
        for data in rawData {
            
            let rowData = data.split(separator: ",")
            
            let dateString = String(rowData[0])
                                        
            let scoreVal = Int(rowData[1])!
            let level = Int(rowData[2]) ?? -1

            let score = Score(date: dateString.simpleDate, score: scoreVal, level: level)
        
            
            if scoreMan.data[dateString] == nil {
                
                scoreMan.data[dateString] = [score]
                
            } else {
                
                scoreMan.data[dateString]!.append(score)
                
            }
                        
        }
        
        return scoreMan
        
    }
    
}
