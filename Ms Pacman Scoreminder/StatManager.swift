//
//  StatManager.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

typealias CSV = String
typealias DateString = String
typealias HTML = String

class StatManager {
    
    private (set) var prefs = Preferences.shared
    var stats: Stats!
    
    init() {
        
        stats = Stats()
        
    }
    
    // Adds or updates score in the data hash
    func set(_ score: Score) {
        
        var currScores = getScoresFor(score.date.simple)
        let date = score.date.simple
        
        if currScores.count == 0 {
            
            setData(date,
                    using: [score])
            
            save()
            
            return /*EXIT*/
            
        }
        
        for i in 0..<currScores.count {
            
            if currScores[i] == score {
                
                currScores[i] = score
                
                setData(date,
                        using: currScores)
                
                save()
                
                return /*EXIT*/
                
            }
            
        }
        
        currScores.append(score)
        
        setData(date,
                using: currScores)
        
        save()
        
    }
    
    /// Deletes a score from `data`
    func delete(_ score: Score) {
        
        let date = score.date.simple
        var scores = getScoresFor(date)
        
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
    func getLowscore()  -> Score? { stats.lowScore }
    func getAvgScore()  -> Score? { stats.avgScore }
    
    /// Returns the number of elements in the `[String]` returned by `getDisplayStats(:)`
    ///
    /// - note: this is not to be confused with the total number of games played (cf `getTotalGamesPlayed()`)
    func getStatCount() -> Int {
        
        if let sample = getScores(sortedBy: .date).first {
            
            return getDisplayStats(sample).count
            
        } else { return 0 }
        
    }
    
    /// Returns a `[String]` of ready to display score stats.
    func getDisplayStats(_ score: Score) -> [String] {
        
        let sortBy: ScoreSortOrder = (score.scoreType == .average ? .avgHigh : .high)
        
        let scores = getScores(sortedBy: sortBy)
        
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
                        
                        percentile = StatManager.percentile(rank, of: scoreCount)
                        
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
        var high = Int.min
        
        var lowScore: Score?
        var low = Int.max
        
        // Average
        var scoreSum = 0
        var levelSum = 0
        var totalScores = 0
        
        // Build Scores
        let scoreData = getScoreData()
        var scores = [Score]()
        
        for dayScores in scoreData.values {
            
            for score in dayScores {
                
                // Initialize Scores
                if highScore == nil {
                    
                    highScore = score
                    high = score.score
                    
                    lowScore = score
                    low = score.score
                    
                }
                
                scoreSum    += score.score
                levelSum    += score.level
                totalScores += 1
                
                // Update Scores
                scores.append(score)
                
                // General Stats
                stats.levelTally![score.level] += 1
                
                // Process Highs
                if score.score > high {
                    
                    high = score.score
                    highScore = score
                    
                    
                } else if   score.score == high
                                && highScore!.date < score.date {
                    
                    high        = score.score
                    highScore   = score
                    
                }
                
                // Process Lows
                if score.score < low {
                    
                    low         = score.score
                    lowScore    = score
                    
                } else if   score.score == low
                                && lowScore!.date < score.date {
                    
                    low         = score.score
                    lowScore    = score
                    
                }
                
            }
            
        }
        
        // Streaks
        setStreaks(with: Array(scoreData.keys))
        
        setScores(scores)
        
        stats.gamesCount    = scores.count
        stats.highScore     = highScore
        stats.lowScore      = lowScore
        stats.avgScore      = Score(date: Date(),
                                    score: scoreSum / totalScores,
                                    level: levelSum / totalScores)
        
    }
    
    /// - important: do not call directly, call `tallyAllStats` instead
    private func tallyDailyStats() {
        
        var dailies = [DailyStats]()
        
        for date in stats.dates {
            
            let scores = getScoresFor(date)
            
            if scores.count < 2 { continue /*CONTINUE*/ }
            
            var daily = DailyStats()
            
            var scoreSum = 0
            var levelSum = 0
            
            scores.forEach{
                
                scoreSum += $0.score
                levelSum += $0.level
                
                daily.levelsReached[$0.level] += 1
                
            }
            
            daily.date          = date.simpleDate
            daily.averageScore  = scoreSum / scores.count
            daily.averageLevel  = Int((levelSum.double / scores.count.double).rounded())
            
            daily.gamesPlayed     = scores.count
            
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
                
            case .avgRecents:
                return getScores(sortedBy: .avgDate).sub(start: 0,
                                                         end: end)
                
                
            case .avgHighsHighFirst:
                return getScores(sortedBy: .avgHigh).sub(start: 0,
                                                         end: end)
                
            case .avgHighsNewFirst:
                return getScores(sortedBy: .avgHigh).sub(start: 0,
                                                         end: end).sorted{ $0.date > $1.date }
                
            case .avgLowsLowFirst:
                return getScores(sortedBy: .avgLow).sub(start: 0,
                                                        end: end)
                
            case .avgLowsNewFirst:
                return getScores(sortedBy: .low).sub(start: 0,
                                                     end: end).sorted{ $0.date > $1.date }
                
        }
        
    }
    
    func getFilterLabel() -> String { String(describing: prefs.scoreSortFilter) }
    
    func setFilter(_ type: ScoreSortFilter.FilterType,
                   daily: Bool,
                   dateSorted: Bool) {
        
        prefs.scoreSortFilter.setFilter(type,
                                        daily: daily,
                                        dateSorted: dateSorted)
        
    }
    
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
            
            var scores      = getScoresFor(date)
            
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
    
    static func percentile(_ num: Int, of: Int) -> String {
        
        let len = (num == 1) ? 3 : 4
        return num.percentile(of: of, roundedTo: 1).description.rTrimTo(len)
        
    }
    
}

extension StatManager: CustomStringConvertible {
    
    var description: String {
        var i = 0
        var descr = ""
        
        for scores in getScoreData().values {
            
            descr += "\(i) : \(scores)\n"
            i += 1
            
        }
        
        return descr
        
    }
    
}
