//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

typealias CSV = String
typealias DateString = String

struct ScoreManager {
    
    private var highScore: Score?
    private var gamesCount  = 0
    private var prefs       = Preferences.shared

    /// A bit flag, setting to true causes all stats to be re-calculated next time data is to be read.
    /// - important: set this to true any time `data` is changed, do not set to false, this should only
    /// be done at end of call to tallyAllStats.
    private var needsTally = true

    /// Underlying data model driving entire app
    /// - important: needsTally bit flag set to true when data.didSet is called
    private var data: [ DateString : [Score] ] { didSet { needsTally = true } }
    
    private var scores = [Score]()
    private var scoresDateSorted    = [Score]()
    private var scoresHighSorted    = [Score]()
    private var scoresLowSorted     = [Score]()
    
    /// Summary of stats for each day's data in `data`
    private var dailyStats = [DailyStats]()
    
    /// Array for tracking number of games played to each level.
    private var levelTally: [Int]?
    
    init() { data = [String : [Score]]() }
    
    // Adds or updates score in the data hash
    mutating func set(_ score: Score) {
        
        guard var currData = data[score.date.simple]
        else {
            
            self.data[score.date.simple] = [score]
            
            save()
                        
            return /*EXIT*/
            
        }
        
        for i in 0..<currData.count {
            
            if currData[i] == score {
                
                currData[i] = score
                
                self.data[score.date.simple] = currData
                
                save()
                                
                return /*EXIT*/
                
            }
            
        }
        
        currData.append(score)
        
        self.data[score.date.simple] = currData
        
        save()
                
    }
    
    /// Deletes a score from `data`
    mutating func delete(_ score: Score) {
        
        guard var data = data[score.date.simple]
        else { return /*EXIT*/ }
        
        for i in 0..<data.count {
            
            if data[i] == score {
                
                data.remove(at: i)
                self.data[score.date.simple] = data
                
                save()
                
                return /*EXIT*/
                
            }
            
        }
        
    }
    
    mutating func getMoneySpent() -> String {
        
        let money       = getGamesCount() * 25
        var moneyText   = "$\(money)"
        
        moneyText.insert(".", at: moneyText.index(moneyText.endIndex, offsetBy: -2))
        
        return moneyText
        
    }
    
    mutating func getGamesCount() -> Int {
        
        tallyAllStats()
        
// TODO: Clean Up - delete
//        if gamesCount == 0 { tallyAllStats() }
        
        return gamesCount
        
    }
    
    mutating func getHighscore() -> Score? {
        
        tallyAllStats()
        
// TODO: Clean Up - delete
//        if highScore == nil { tallyAllStats() }
        
        return highScore
        
    }
    
    /// Returns the number of elements in the `[String]` returned by `getStats(:)`
    mutating func getStatCount() -> Int { getStats(scores.first!).count }
    
    /// Returns a `[String]` of ready to display score stats.
    mutating func getStats(_ score: Score) -> [String] {
        
        tallyAllStats()
        
        for (i, data) in scoresHighSorted.enumerated() {
            
            if score == data {
                
                let scoreCount = scores.count
                let rank = i + 1
                var percentile = String()
                
                switch rank {
                    
                case 1:
                    
                    percentile = " ★ "
                    
                case scoreCount:
                    
                    percentile = "LOW"
                    
                default:
                    
                    percentile = (( rank.double / scoreCount.double ) * 100).roundTo(1).description.rTrimTo(4)
                    percentile = "\(percentile)%"
                    
                }
                
                return [rank.description, percentile] /*EXIT*/
                
            }
            
        }
        
        return []
        
    }
    
    mutating func filter(count: Int) -> [Score] {
        
        tallyAllStats()
        
        let end = min(count, gamesCount) - 1
        
        if end < 0 { return [] }
        
        switch prefs.scoreSortFilter {
            
        case .highsHighFirst:
            return scoresHighSorted.sub(start: 0, end: end)
            
        case .highsNewFirst:
            return scoresHighSorted.sub(start: 0, end: end).sorted{ $0.date > $1.date }
            
        case .recents:
            return scoresDateSorted.sub(start: 0, end: end)
            
        case .lowsLowFirst:
            return scoresLowSorted.sub(start: 0, end: end)
            
        case .lowsNewFirst:
            return scoresLowSorted.sub(start: 0, end: end).sorted{ $0.date > $1.date }
            
        }
        
        
    }
    func getFilterLabel() -> String { String(describing: prefs.scoreSortFilter) }
    
    // TODO: Clean Up - need to call tallyAllStats here?
    func getScores(forDateString date: String) -> [Score] { data[date] ?? [Score]() }
    
    // Converts data to [["Date", "Score", "Level"]]
    mutating func getScoreArray() -> (score: [[String]], headers: [String]) {
        
        tallyAllStats()
        
        var scoreArray = [[String]]()
        
        let scores = scoresDateSorted
        
        for score in scores {
            
            scoreArray.append([score.date.simple,
                               score.score.description,
                               score.level.description])
            
        }
        
        return (scoreArray, ["Date", "Score", "Level"])
        
    }
    
    mutating func getScoreReport(forDateString date: String = Date().simple) -> String {
        
        tallyAllStats()
        
        let rawData = getScores(forDateString: date)
        
        var data = [[String]]()
        
        for datum in rawData {
            
            data.append([datum.date.simple, datum.displayScore, datum.levelString])
            
        }
        
        var report = ""
        let headers = ["Date", "Score", "Level"]
        if data.count > 0 {
            
            report = Report.columnateAutoWidth(data, headers: headers,
                                               title: "Scores for \(Date().simple)")
            
        }
        
        return report
        
    }
    
    mutating func getLevelReport() -> String {
        
        tallyAllStats()
        
        var rowData = [[String]]()
                
        for (level, count) in levelTally!.enumerated() {
            
            let percent = ((count.double / gamesCount.double) * 100).roundTo(1)
            rowData.append([Score.nameFor(level: level), "\(count)", "\(percent)%"])
            
        }
        
        var report = ""
        let headers = ["Level", "Count", "Percent"]
        
        if rowData.count > 0 {
            
            report = Report.columnateAutoWidth(rowData,
                                               headers: headers,
                                               title: "Levels Reached")
            
        }
        
        return report
        
    }
    
    /// Calculates all stats and only executes when needsTally is set to `true`
    /// - important: Should be called before any attempt is made to read from `data`, `scores`, or `dailyStats`
    /// - important: `needsTally` should be set to true any time data is changed.
    mutating func tallyAllStats() {
        
        if !needsTally { return /*EXIT*/ }
        
        needsTally = false
        
        tallyScoreStats()
        tallyDailyStats()
        
    }
    
    /// - important: do not call directly, call `tallyAllStats` instead
    mutating private func tallyScoreStats() {
        
        levelTally = Array(repeating: 0, count: Score.levelCount)
        
        var highScore: Score?
        var high = 0
        
        // reset scores
        scores = [Score]()
        
        for dayScores in data.values {
            
            for score in dayScores {

                // update scores
                scores.append(score)
                
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
        
        self.gamesCount = scores.count
        self.highScore  = highScore
        
        scoresDateSorted    = scores.sorted{ $0.date > $1.date }
        scoresHighSorted    = scores.sorted{ $0.score > $1.score }
        scoresLowSorted     = scores.sorted{ $0.score < $1.score }
        
    }
    
    /// - important: do not call directly, call `tallyAllStats` instead
    mutating private func tallyDailyStats() {
        
        var dailies = [DailyStats]()
        
        for dateString in data.keys {
            
            guard let scores = data[dateString],
                  scores.count > 0
            else { continue  /*EXIT*/ }
            
            var daily = DailyStats()
            
            var sum = 0
            scores.forEach{ sum += $0.score }
            
            daily.date          = dateString.simpleDate
            daily.averageScore  = sum / scores.count
            daily.gameCount     = scores.count
            
            dailies.append(daily)
            
        }
        
        // sort
        dailyStats = dailies.sorted{$0 > $1}
        
        // set ranks
        for i in 0...dailyStats.lastUsableIndex {
            
            dailyStats[i].rank = (i + 1, dailyStats.count)
            
        }
        
    }
    
    mutating func getDailyStats(_ date: DateString) -> DailyStats? {
        
        getDailyStats(date.simpleDate)
        
    }
    
    mutating func getDailyStats(_ date: Date) -> DailyStats? {
        
        tallyAllStats()
        
        for daily in dailyStats {
            
            if daily.date.simple == date.simple { return daily /*EXIT*/ }
            
        }
        
        return nil
        
    }
    
    
    func cylecFilter() {
        
        prefs.scoreSortFilter.cycleNext()
        
    }
    
}

// MARK: - Data Storage
extension ScoreManager {
    
    static func importData(from csv: CSV) -> ScoreManager {
        
        var scoreMan = ScoreManager()
        let rawData = csv.split(separator: "\n")
        
        for data in rawData {
            
            let rowData = data.split(separator: ",")
            
            let dateString = String(rowData[0])
            
            let scoreVal = Int(rowData[1])!
            let level = Int(rowData[2]) ?? -1
            
            let score = Score(date: dateString.simpleDate,
                              score: scoreVal,
                              level: level)
            
            
            if scoreMan.data[dateString] == nil {
                
                scoreMan.data[dateString] = [score]
                
            } else {
                
                scoreMan.data[dateString]!.append(score)
                
            }
            
        }
        
        return scoreMan
        
    }
    
    func getCSV() -> CSV {
        
        var output = ""
        
        for score in scoresDateSorted {
            
            output += "\(score.date.simple),\(score.score),\(score.level)\n"
            
        }
        
        return output
        
    }
    
    func save() { save(getCSV()) }
    
    private func save(_ csv: CSV,
                      toFile: String = Configs.File.currentDataPath) {
        
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
        
        let savedData       = FileManager.default.contents(atPath: Configs.File.currentDataPath)
        let saveDataExists  = savedData != nil
        let useDefaults     = Configs.Test.shouldRevertToDefaultData || !saveDataExists
        
        if saveDataExists {
            
            csv = String(decoding: savedData!,
                         as: UTF8.self)
            
            if useDefaults {
                
                // backup old data
                let backupFilePath = Configs.File.generateBackupFilePath()
                NSLog("Backing up: \(backupFilePath)")
                save(csv, toFile: backupFilePath)
                
            } else {
                
                NSLog("Loading: \(Configs.File.currentDataPath)")
                
            }
            
        }
        
        if useDefaults {
            
            // load reset data
            NSLog("Loading Defaults: \(Configs.File.defaultDataPath)")
            
            let savedData   = FileManager.default.contents(atPath: Configs.File.defaultDataPath)
            csv = String(decoding: savedData!,
                         as: UTF8.self)
            
            save(csv)
            
        }
        
        self = ScoreManager.importData(from: csv)
        
        tallyAllStats()
        
    }
    
    /// Runs a series of data checks, presenting an alert at the first one that doesn't pass.
    /// - warning: this method is relatively expensive has to open and scan documentDirectory
    /// - important: this method calls displays an Alert and must be called in viewDidAppear.
    func warningsCheck() {
        
        // Backup Count Check
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var csvCount = Int.max
        
        do {
            
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            csvCount = directoryContents.filter{ $0.pathExtension == "csv" }.count - 1
            
        } catch { print(error) }
        
        // Default Override
        if Configs.Test.shouldRevertToDefaultData {
            
            let alertText: AlertText = (title: "Warning!",
                                        """
                                            Reverting to default data, all current\
                                            data is being backed up.
                                        
                                            Backup Count: \(csvCount)
                                        
                                            See Files App
                                        """)
            
            Alert.ok(alertText)
            
        } else {
            
            if csvCount >= Configs.File.maxBackupCount {
                
                Alert.ok(title: "File Accumulation Warning",
                         message: "\nThere are \(csvCount) backup files in Files App.")
                
            }
            
        }
        
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
