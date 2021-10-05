//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

typealias CSV = String

enum Filter: Codable {
    
    case last
    case highs
    case lows
    
    mutating func cycleNext() {
        
        switch self {
            
        case .last: self = .highs
            
        case .highs: self = .lows
            
        case .lows: self = .last
            
        }
        
    }
    
    var labelText: String {

        switch self {
            
        case .last:     return "Recent Scores"
            
        case .highs:    return "High Scores"
            
        case .lows:     return "Low Scores"
            
        }
        
    }
    
}

struct ScoreManager : Codable {

    private var gamesCount = 0
    private var highScore: Score?
    
    private var filter: Filter? = .last
    
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
    
    private var scoresDateSorted: [Score] { scores.sorted{ $0.date > $1.date } }
    private var scoresHighSorted: [Score] { scores.sorted{ $0.score > $1.score } }
    private var scoresLowSorted: [Score] { scores.sorted{ $0.score < $1.score } }
    
    init() { data = [String : [Score]]() }
    
    // Adds or updates score in the data hash
    mutating func set(_ score: Score) {
        
        guard var currData = data[score.date.simple]
        else {
            
            self.data[score.date.simple] = [score]
            
            save()
            
            tallyStats()
            
            return /*EXIT*/
            
        }
        
        for i in 0..<currData.count {
            
            if currData[i] == score {

                currData[i] = score
                
                self.data[score.date.simple] = currData
            
                save()
                
                tallyStats()
                
                return /*EXIT*/
                
            }
            
        }
        
        currData.append(score)
        
        self.data[score.date.simple] = currData
        
        save()
        
        tallyStats()
        
    }
    
    mutating func cylecFilter() {
        
        filter?.cycleNext()
        
    }
    
    mutating func remove(_ score: Score) {
        
        guard var data = data[score.date.simple]
        else { return /*EXIT*/ }
        
        for i in 0..<data.count {
            
            if data[i] == score {
        
print("\(#function) - \(score)")
                
                data.remove(at: i)
                self.data[score.date.simple] = data
                
                tallyStats()
                save()
                
                return /*EXIT*/
                
            }
            
        }
        
        tallyStats()
        
    }
    
    mutating func tallyStats() {

        gamesCount = 0
                
        levelTally = Array(repeating: 0, count: Score.levelCount)
        
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
    
    func getRank(_ score: Score) -> Int {
        
        
        for (i, data) in scoresHighSorted.enumerated() {
            
            if score == data { return i + 1 /*EXIT*/ }
            
        }
        
        return -1 /*EXIT*/
        
    }
    
    mutating func filter(count: Int) -> [Score] {
        
        let end = min(count, gamesCount) - 1
        
        if end < 0 { return [] }
        
        switch filter {
        case .highs:
            return scoresHighSorted.sub(start: 0, end: end)
            
        case .last:
            return scoresDateSorted.sub(start: 0, end: end)
            
        case .lows:
            return scoresLowSorted.sub(start: 0, end: end)
            
        default: filter = .highs
            return scoresHighSorted.sub(start: 0, end: end)
            
        }
        
        
    }
    func getFilterLabel() -> String {
        
        filter?.labelText ?? "-?-"
        
    }
    func getScores(forDateString date: String) -> [Score] {
        
        data[date] ?? [Score]()
        
    }
    
    // Converts data to [["Date", "Score", "Level"]]
    func getScoreArray() -> (score: [[String]], headers: [String]) {
        
        var scoreArray = [[String]]()
                
        let scores = scoresDateSorted
        
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
            rowData.append([Score.nameFor(level: level), "\(count)", "\(percent)%"])
            
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
    
    static func importData(from csv: CSV) -> ScoreManager {
        
        var scoreMan = ScoreManager()
//        let rawData = HistoricScores.data.split(separator: "\n")
        let rawData = csv.split(separator: "\n")

        
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


extension ScoreManager {
    
    func getCSV() -> CSV {
        
        var output = ""
        
        for score in scoresDateSorted {
            
            output += "\(score.date.simple),\(score.score),\(score.level)\n"
            
        }
        
        return output
        
    }
    
    func save() { save(getCSV()) }
    
    private func save(_ csv: CSV,
                      toFile: String = Configs.File.path) {
        
        do {
            
            try csv.write(toFile: toFile,
                           atomically: true,
                           encoding: String.Encoding.utf8)
            
            NSLog("Saved data to: \(toFile)")
            
            
        } catch {
            
            NSLog(error.localizedDescription)
            
        }
        
    }
        
    mutating func open() {
        
        var csv: CSV!

        let savedData       = FileManager.default.contents(atPath: Configs.File.path)
        let saveDataExists  = savedData != nil
        let useHistoric     = Configs.Test.revertToHistoricData || !saveDataExists

        if saveDataExists {

            csv = String(decoding: savedData!,
                         as: UTF8.self)
            
            if useHistoric {
                
                // backup old data
                let backupFilePath = Configs.File.generateBackupPath()
                NSLog("Backing up: \(backupFilePath)")
                save(csv, toFile: backupFilePath)
                
            } else {
                
                NSLog("Loading: \(Configs.File.path)")

            }
            
        }
        
        if useHistoric {

            // load reset data
            NSLog("Loading: HistoricScores.csv")
            csv = HistoricScores.csv
            save(csv)

        }

        self = ScoreManager.importData(from: csv)


    }
  
}

// TODO: Clean Up - move below code into extension above
//extension ScoreManager {
//
//    // TODO: Clean Up - move archival to ScoreManager
//    mutating func unarchive(resetArchive: Bool = false) {
//
//        guard let archived: ScoreManager = CodableArchiver.unarchive(file: Configs.archiveKey,
//                                                                     inSubDir: "")
//        else {
//
//            print("Unarchive failed to find archive, returning empty ScoreData")
//
//            self = ScoreManager.importData(from: HistoricScores.data)
//
//            archive()
//
//            return /*EXIT*/
//
//        }
//
//        self = archived
//
//        if resetArchive {
//
//            let suffix = "\(Configs.csvFile)_\(Date().description)"
//
//            writeCSV(withSuffix: suffix)
//
//            print("Unarchive bypassed. Resetting archive via data import.")
//            print("Old data backed up to '/private/tmp/\(suffix)_v?.?.csv'")
//
//            self = ScoreManager.importData(from: HistoricScores.data)
//
//            return /*EXIT*/
//
//        }
//
//        print("Unarchive succeeded, returning archived ScoreData")
//
//    }
    
//    func archive() {
//
//        CodableArchiver.archive(self,
//                                toFile: Configs.archiveKey,
//                                inSubDir: nil)
//
//    }
    
//    func writeCSV(withSuffix suffix: String) {
//
//        let (scores, headers) = getScoreArray()
//
//        Report.write(data: scores,
//                     headers: headers,
//                     fileSuffix: suffix,
//                     versionOverride: nil)
//
//
//    }
    
//}
