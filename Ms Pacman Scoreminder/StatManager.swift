//
//  StatManager.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import UIKit
import APNUtil

typealias CSV = String
typealias DateString = String
typealias HTML = String

enum DateRange : CustomStringConvertible {
    
    case week, month, year, all, unspecified
    
    var description: String {
        
        switch self {
                
            case .week  : return "Last Week"
                
            case .month : return "Last Month"
                
            case .year  : return "Last Year"
            
            case .all   : return "All"
                
            case .unspecified : return ""
                
        }
        
    }
    
}

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
                        
                        percentile = StatManager.percentileDescription((rank,scoreCount))
                        
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
                if highScore.isNil {
                    
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
                                    level: levelSum / totalScores,
                                    averagedGameCount: totalScores)
        
    }
    
    /// - important: do not call directly, call `tallyAllStats` instead
    private func tallyDailyStats() {
        
        var dailies = [DailyStats]()
        
        for date in stats.dates {
            
            let scores = getScoresFor(date.simple)
            
            if scores.count < 2 { continue /*CONTINUE*/ }
            
            var daily = DailyStats()
            
            var scoreSum = 0
            var levelSum = 0
            
            scores.forEach{
                
                scoreSum += $0.score
                levelSum += $0.level
                
                daily.levelsReached[$0.level] += 1
                
            }
            
            daily.date          = date
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
    
    /// A backing property for filterAll caching the out ouptut of the most recently run filterAll() call.
    private var _filteredAll = [Score]()
    
    /// Returns an `Array` of all `Score`s filtered on current value of `prefs.scoreSortFilter` caching this value in filteredAllCached property for repeated reference.
    /// - important: to ensure data is uptodate, set `refreshData` to `true`.  Use `refreshData = false` for repetitive calls with no intervening stat/filter changes.
    func filterAll(refreshData: Bool,
                   dateRange: DateRange,
                   returnCount: Int? = nil,
                   percentOfCount percent: Double? = nil) -> [Score] {
        
        var isDateSorted = false
        
        if refreshData || _filteredAll.count < 1 {
            
            switch prefs.scoreSortFilter {
                    
                case .highsHighFirst:
                    _filteredAll = getScores(sortedBy: .high)
                    
                case .highsNewFirst:
                    _filteredAll = getScores(sortedBy: .high).sorted{ $0.date > $1.date }
                    isDateSorted = true
                    
                case .recents:
                    _filteredAll = getScores(sortedBy: .date)
                    isDateSorted = true
                    
                case .lowsLowFirst:
                    _filteredAll = getScores(sortedBy: .low)
                    
                case .lowsNewFirst:
                    _filteredAll = getScores(sortedBy: .low).sorted{ $0.date > $1.date }
                    isDateSorted = true
                    
                case .avgRecents:
                    _filteredAll = getScores(sortedBy: .avgDate)
                    isDateSorted = true
                    
                case .avgHighsHighFirst:
                    _filteredAll = getScores(sortedBy: .avgHigh)
                    
                case .avgHighsNewFirst:
                    _filteredAll = getScores(sortedBy: .avgHigh).sorted{ $0.date > $1.date }
                    isDateSorted = true
                    
                case .avgLowsLowFirst:
                    _filteredAll = getScores(sortedBy: .avgLow)
                    
                case .avgLowsNewFirst:
                    _filteredAll = getScores(sortedBy: .avgLow).sorted{ $0.date > $1.date }
                    isDateSorted = true
                    
            }
            
        }
        
        func getCount(mostRecentDays: Int) -> Int {
            
            if !isDateSorted { return mostRecentDays }
            
            var count = 0
            let today = Date()
            
            for score in _filteredAll {
                
                if today.daysFrom(earlierDate: score.date) >= mostRecentDays { break /*BREAK*/ }
                
                count += 1
                    
            }
            
            return count
            
        }
        
        let count: Int

        switch dateRange {
                
            case .week:     count = getCount(mostRecentDays: 7)
                
            case .month:    count = getCount(mostRecentDays: 30)
                
            case .year:     count = getCount(mostRecentDays: 365)
                
            case .all :     count = _filteredAll.count
                
            case .unspecified :
                
                // TODO: Clean Up - clarify logic for generating count here...
                count = returnCount ?? max(1, Int(_filteredAll.count.double * (percent ?? 1.0)))
                
        }
        
        let filtered = Array(_filteredAll.prefix(count))
        
        return filtered
        
    }
    
    /// Returns the first `count` of *uncached* `Score`s from `filterAll()`
    func filter(count: Int) -> [Score] {
        
        let data = filterAll(refreshData: true, dateRange: .unspecified, returnCount: count)
        
        let end = min(count, data.count) - 1
        
        if end < 0 { return [] }
        
        return data.sub(start: 0, end: end)
        
    }
    
    func getFilterLabel(dateRange: DateRange) -> String {
        
        let baseText    = String(describing: prefs.scoreSortFilter)
        var rangeText   = String(describing: dateRange)
        
        rangeText       = dateRange == .unspecified ? "" : " (\(rangeText))"
        
        return "\(baseText)\(rangeText)"
        
    }
    
    /// Returns the current value of Preferences.shared.scoreSortFilter
    func getFilter() -> ScoreSortFilter { prefs.scoreSortFilter }
    
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
    
    
    /// Retrieves archived `Score` data from saved file.
    ///
    /// - note: this is an expensive call.
    /// - Parameter completion: Completion handler.
    func open(completion: (() -> ())? = nil) {
        
        var csv: CSV!
        
        let savedData       = FileManager.default.contents(atPath: Configs.File.Path.currentData)
        let saveDataExists  = savedData.isNotNil
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
        
        completion?()
        
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
    
    
    static func rankCompare(_ rank1: (Int,Int), _ rank2: (Int,Int)) -> (Double, Int) {
        
        let pct1 = percentile(rank1)
        let pct2 = percentile(rank2)
        let rank1 = rank1.0
        let rank2 = rank2.0
        
        return (pct2 - pct1, rank2 - rank1)
        
    }
    
    private static func percentile(_ rank: (Int, Int)) -> Double {
        
        rank.0.percentile(of: rank.1, roundedTo: 1)
        
    }
    
    static func percentileDescription(_ rank: (Int, Int)) -> String {

        let len = (rank.0 == 1) ? 3 : 4
        
        return percentile(rank).description.rTrimTo(len)
        
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
