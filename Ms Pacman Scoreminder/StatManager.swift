//
//  StatManager.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

typealias CSV = String
typealias DateString = String

class StatManager {
    
    private var prefs       = Preferences.shared
    var stats: Stats!
    
    init() {
        
        stats = Stats()
        
    }
    
    // Adds or updates score in the data hash
    func set(_ score: Score) {
        
        var currData = getDataFor(score.date.simple)
        let date = score.date.simple
        
        if currData.count == 0 {
            
            setData(date,
                          using: [score])
            
            save()
            
            return /*EXIT*/
            
        }
        
        for i in 0..<currData.count {
            
            if currData[i] == score {
                
                currData[i] = score
                
                setData(date,
                              using: currData)
                
                save()
                
                return /*EXIT*/
                
            }
            
        }
        
        currData.append(score)
        
        setData(date,
                      using: currData)
        
        save()
        
    }
    
    /// Deletes a score from `data`
    func delete(_ score: Score) {
        
        let date = score.date.simple
        var scores = getDataFor(date)
        
        if scores.count == 0 { return /*EXIT*/ }
        
        for i in 0..<scores.count {
            
            if scores[i] == score {
                
                scores.remove(at: i)
                
                setData(date, using: scores)
                
                save()
                
                return /*EXIT*/
                
            }
            
        }
        
    }
    
    func getMoneySpent() -> String {
        
        let money       = stats.gamesCount * 25
        
        var moneyText   = "$\(money)"
        
        moneyText.insert(".", at: moneyText.index(moneyText.endIndex, offsetBy: -2))
        
        return moneyText
        
    }
    
    func getHighscore() -> Score? { stats.highScore }
    
    /// Returns the number of elements in the `[String]` returned by `getStats(:)`
    func getStatCount() -> Int {
        
        if let sample = getScores(sortedBy: .date).first {
            
            return getDisplayStats(sample).count
            
        } else { return 0 }
        
    }
    
    /// Returns a `[String]` of ready to display score stats.
    func getDisplayStats(_ score: Score) -> [String] {
        
        let scores = getScores(sortedBy: .high)
        
        for (i, data) in scores.enumerated() {
            
            if score == data {
                
                let scoreCount = stats.gamesCount
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
    
    // Converts data to [["Date", "Score", "Level"]]
    func getScoreArray() -> (score: [[String]], headers: [String]) {
        
        var scoreArray = [[String]]()
        
        let scores = getScores(sortedBy: .date)
        
        for score in scores {
            
            scoreArray.append([score.date.simple,
                               score.score.description,
                               score.level.description])
            
        }
        
        return (scoreArray, ["Date", "Score", "Level"])
        
    }
    
    func getScoreReport(forDateString date: DateString = Date().simple) -> String {
        
        let rawData = getDataFor(date)
        
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
    
    func getLevelReport() -> String {
        
        var rowData = [[String]]()
        
        for (level, count) in stats.levelTally!.enumerated() {
            
            let percent = ((count.double / stats.gamesCount.double) * 100).roundTo(1)
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
    
    /// Tallies all stats and only executes when needsTally is set to `true`
    /// - important: Should be called before any attempt is made to read from `data`, `scores`, or `dailyStats`
    /// - important: `needsTally` should be set to true any time data is changed.
    func tally() {
        
        if stats.needsTally {
            
            clearNeedsTally()
            
            tallyScoreStats()
            tallyDailyStats()
            
        }
        
    }
    
    /// - important: do not call directly, call `tallyAllStats` instead
    private func tallyScoreStats() {
        
        stats.levelTally = Array(repeating: 0, count: Score.levelCount)
        
        var highScore: Score?
        var high = 0
        
        // build scores
        var scores = [Score]()
        
        for dayScores in getScores().values {
            
            for score in dayScores {
                
                // update scores
                scores.append(score)
                
                // General Stats
                stats.levelTally![score.level] += 1
                
                // High Score
                if score.score > high {
                    
                    high = score.score
                    highScore = score
                    
                }
                
            }
            
        }
        
        setScores(scores)
        stats.gamesCount = scores.count
        stats.highScore  = highScore
        
    }
    
    /// - important: do not call directly, call `tallyAllStats` instead
    private func tallyDailyStats() {
        
        var dailies = [DailyStats]()
        
        for date in stats.dates {
            
            let scores = getDataFor(date)
            
            if scores.count == 0 { return /*EXIT*/ }
            
            var daily = DailyStats()
            
            var scoreSum = 0
            var levelSum = 0
            
            scores.forEach{
                
                scoreSum += $0.score
                levelSum += $0.level
                
            }
            
            daily.date          = date.simpleDate
            daily.averageScore  = scoreSum / scores.count
            daily.averageLevel  = Int((levelSum.double / scores.count.double).rounded())
            
            daily.gameCount     = scores.count
            
            dailies.append(daily)
            
        }
        
        // sort
        dailies.sort(by: >)
        
        let totalDaysPlayed = dailies.count
        
        for (i, _) in dailies.enumerated() {
            
            dailies[i].rank = (i + 1, totalDaysPlayed)
            
        }
        
        setDailys(dailies)
        
    }
    
    func filter(count: Int) -> [Score] {
        
        let end = min(count, stats.gamesCount) - 1
        
        if end < 0 { return [] }
        
        switch prefs.scoreSortFilter {
            
        case .highsHighFirst:
            return getScores(sortedBy: .high).sub(start: 0,
                                                        end: end)
            
        case .highsNewFirst:
            return getScores(sortedBy: .high).sub(start: 0,
                                                        end: end).sorted{ $0.date > $1.date }
            
        case .recents:
            return getScores(sortedBy: .date).sub(start: 0,
                                                        end: end)
            
        case .lowsLowFirst:
            return getScores(sortedBy: .low).sub(start: 0,
                                                       end: end)
            
        case .lowsNewFirst:
            return getScores(sortedBy: .low).sub(start: 0,
                                                       end: end).sorted{ $0.date > $1.date }
            
        }
        
    }
    
    func getFilterLabel() -> String { String(describing: prefs.scoreSortFilter) }
    
    func cylecFilter() { prefs.scoreSortFilter.cycleNext() }
    
}

// MARK: - Data Storage
extension StatManager {
    
    func importData(from csv: CSV) {
        
        let rawData = csv.split(separator: "\n")
        
        // TODO: Clean Up - aggregate all imported data before saving to stats.data
        for data in rawData {
            
            let rowData     = data.split(separator: ",")
            
            let date        = String(rowData[0])
            
            let scoreVal    = Int(rowData[1])!
            let level       = Int(rowData[2]) ?? -1
            
            var scores      = getDataFor(date)
            
            let score       = Score(date: date.simpleDate,
                                    score: scoreVal,
                                    level: level)
            
            scores.append(score)
            
            setData(date, using: scores)
            
        }
        
    }
    
    func getCSV() -> CSV {
        
        // tally before collating stats in csv
        tally()
        
        var output = ""
        
        let scores = getScores(sortedBy: .date)
        
        for score in scores {
                        
            output += "\(score.date.simple),\(score.score),\(score.level)\n"
            
        }
        
        return output
        
    }
    
    func save() { save(getCSV()) }
    
    private func save(_ csv: CSV,
                      toFile: String = Configs.File.Path.currentData) {
        
        do {
            
            try csv.write(toFile: toFile,
                          atomically: true,
                          encoding: String.Encoding.utf8)
            
            NSLog("Saved data to: \(toFile)")
            
            
        } catch {
            
            NSLog(error.localizedDescription)
            
        }
        
    }
    
    func open() {
        
        var csv: CSV!
        
        let savedData       = FileManager.default.contents(atPath: Configs.File.Path.currentData)
        let saveDataExists  = savedData != nil
        let useDefaults     = Configs.Test.shouldReloadData || !saveDataExists
        
        if saveDataExists {
            
            csv = String(decoding: savedData!,
                         as: UTF8.self)
            
            if useDefaults {
                
                // backup old data
                let backupFilePath = Configs.File.Path.generateBackupFilePath()
                NSLog("Backing up: \(backupFilePath)")
                save(csv, toFile: backupFilePath)
                
            } else {
                
                NSLog("Loading: \(Configs.File.Path.currentData)")
                
            }
            
        }
        
        if useDefaults {
            
            // load reset data
            NSLog("Loading Defaults: \(Configs.File.Path.defaultData)")
            
            let savedData   = FileManager.default.contents(atPath: Configs.File.Path.defaultData)
            csv = String(decoding: savedData!,
                         as: UTF8.self)
            
            save(csv)
            
        }
        
        importData(from: csv)
        
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
        if Configs.Test.shouldReloadData {
            
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

extension StatManager: CustomStringConvertible {
    
    var description: String {
        var i = 0
        var descr = ""
        
        for scores in getScores().values {
            
            descr += "\(i) : \(scores)\n"
            i += 1
            
        }
        
        return descr
        
    }
    
}