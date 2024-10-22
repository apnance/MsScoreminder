//
//  StatManager.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import UIKit
import APNUtil
import ConsoleView

typealias CSV = String

/// A string formatted as `Date.simple`
typealias DateStringSimple = String
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

/// Manages game `Stats` and `DailyStats`
class StatManager {
    
    private var saveNeeded  = false
    private (set) var prefs = Preferences.shared
    var stats: Stats!
    
    private var _csv: CSV?
    private(set) var csv: CSV {
        
        get { _csv.isNil ? getCSV() : _csv! }
        
        set { _csv = newValue }
        
    }
    
    init() { stats = Stats() }
    
    // Adds or updates score in the data hash then sets `saveNeeded = true`
    func set(_ score: Score) {
        
        assert(score.score % 10 == 0,
                """
                Score: \(score.score) is not a multiple of 10.  Ms. Pac-Man 
                scores are all multiples of 10.
                """)
        
        saveNeeded = true
        
        var currScores = getScoresFor(score.date)
        let date = score.date.simple
        
        if currScores.count == 0 {
            
            setData(date,
                    using: [score])
            
            return /*EXIT*/
            
        }
        
        for i in 0..<currScores.count {
            
            if currScores[i] == score {
                
                currScores[i] = score
                
                setData(date,
                        using: currScores)
                
                return /*EXIT*/
                
            }
            
        }
        
        currScores.append(score)
        
        setData(date,
                using: currScores)
        
    }
    
    /// Deletes a score from `data` saving if `shouldSave` is true.
    ///
    /// - important: do not set `shouldSave` to true if there is potential of
    /// another concurrent call to `save()` multiple calls to `save()` will result
    /// in crash.
    func delete(_ score: Score, shouldSave: Bool = false) {
        
        var scores = getScoresFor(score.date)
        
        if scores.count == 0 { return /*EXIT*/ }
        
        let dateSimple = score.date.simple
        
        for i in 0..<scores.count {
            
            if scores[i] == score {
                
                scores.remove(at: i)
                
                setData(dateSimple, using: scores)
                
                if shouldSave { saveNeeded = true }
                
                return /*EXIT*/
                
            }
            
        }
        
    }
    
    func getMoneySpent() -> String {
        
        let money       = stats.singleGamesCount * 25
        
        var moneyText   = "$\(money)"
        
        moneyText.insert(".", at: moneyText.index(moneyText.endIndex, offsetBy: -2))
        
        return moneyText
        
    }
    
    func getFirstRecordedScore() -> Score? {
        
        guard let fpd = stats.firstPlayDate
        else { return nil }
        
        return getScoresFor(fpd).first
        
    }
    
    func getLastRecordedScore() -> Score? {
        
        guard let lpd = stats.lastPlayDate
        else { return nil }
        
        return getScoresFor(lpd).first
        
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
        
        let sortBy: ScoreSortOrder = (score.isAveraged ? .avgHigh : .high)
        
        let scores = getScores(sortedBy: sortBy)
        
        for (i, data) in scores.enumerated() {
            
            if score == data {
                
                let scoreCount      = score.isSingle ? stats.singleGamesCount : stats.averagedGamesCount
                let rank            = i + 1
                var percentile      = String()
                
                switch rank {
                        
                    case 1:
                        
                        percentile  = " ★ "
                        
                    case scoreCount:
                        
                        percentile  = "LOW"
                        
                    default:
                        
                        percentile  = StatManager.percentileDescription((rank,scoreCount))
                        
                }
                
                return [rank.description, percentile] /*EXIT*/
                
            }
            
        }
        
        return []
        
    }
    
    /// Tallies all stats and only executes when needsTally is set to `true`
    /// - important: Should be called before any attempt is made to read from `data`, `scores`, or `dailyStats`
    /// - important: `needsTally` should be set to true any time data is changed.
    func tally() {
        
        if stats.needsTally {
            
            clearNeedsTally()
            
            sortAndSetDates()
            
            tallyScoreStats()
            
            tallyDailyStats()
            
        }
        
    }
    
    /// - important: do not call directly, *call `tally` instead*
    private func tallyScoreStats() {
        
        stats.levelTally = Array(repeating: 0,
                                 count: Score.levelCount)
        
        // Invalid Defaults
        for i in 0..<Score.levelCount {
            
            let invalid = Score.invalid(withLevel: i)
            stats.optimals.append(invalid)
            stats.optimalsDaily.append(invalid)
            
        }
        
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
                
                // level
                let levelNum    = score.level.num
                scoreSum        += score.score
                levelSum        += levelNum
                totalScores     += 1
                
                // Update Scores
                scores.append(score)
                
                // General Stats
                stats.levelTally![levelNum] += 1
                
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
                
                // Process Optimals
                if score.score > stats.optimals[levelNum].score {
                    
                    stats.optimals[levelNum] = score
                    
                }
                
            }
            
        }
        
        // Streaks
        setStreaks(with: Array(scoreData.keys))
        
        setSortedScoreArrays(scores)
        
        stats.singleGamesCount  = scores.count
        stats.highScore         = highScore
        stats.lowScore          = lowScore
        stats.avgScore          = Score(date: Date(),
                                        score: scoreSum / totalScores,
                                        level: levelSum / totalScores,
                                        averagedGameCount: totalScores)
        
    }
    
    /// - important: do not call directly, call `tally` instead
    private func tallyDailyStats() {
        
        var dailies = [DailyStats]()
        
        let lastSevenDailies = Queue<DailyStats>()
        
        for date in stats.dates { // Iterates Chronologically
           
            let scores = getScoresFor(date)
            
            if scores.count < 2 { continue /*CONTINUE*/ }
            
            var currentDaily = DailyStats()
            
            var scoreSum = 0
            var levelSum = 0
            
            scores.forEach{
                
                scoreSum += $0.score
                levelSum += $0.level.num
                
                currentDaily.levelsReached[$0.level.num] += 1
                
            }
            
            currentDaily.date          = date
            currentDaily.averageScore  = scoreSum / scores.count
            currentDaily.averageLevel  = Int((levelSum.double / scores.count.double).rounded())
            currentDaily.gamesPlayed   = scores.count
            
            // 7-Day Avg
            lastSevenDailies.enqueue(item: currentDaily, withMaxCount: 7)
            currentDaily.sevenDayAverage = lastSevenDailies.reduce(0){ $0 + $1.averageScore } / lastSevenDailies.count
            
            dailies.append(currentDaily)
            
        }
        
        dailies.sort(by: >) // Sorted by averageScore
        
        let totalDaysPlayed = dailies.count
        
        for (i, daily) in dailies.enumerated() {
            
            dailies[i].rank = (i + 1, totalDaysPlayed)
            
            // Process Optimals
            let (scoreNum, levelNum) = (daily.averageScore, daily.averageLevel)
            if scoreNum > stats.optimalsDaily[daily.averageLevel].score {
                
                stats.optimalsDaily[daily.averageLevel] = Score(date:  daily.date,
                                                                score: scoreNum,
                                                                level: levelNum)
                
            }
            
        }
        
        setDailys(dailies)
        
    }
    
    /// Run StatLab analyses here
    ///
    /// e.g. StatLab was used to generate score-level prediction ranges
    func runStatLab() -> String {
        
        StatLab.analyze(getScores(sortedBy: .date))
        
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
                    
                case .optimals:
                    _filteredAll = getOptimals(useDaily: false)
                    isDateSorted = true
                    
                case .lowsLowFirst:
                    _filteredAll = getScores(sortedBy: .low)
                    
                case .lowsNewFirst:
                    _filteredAll = getScores(sortedBy: .low).sorted{ $0.date > $1.date }
                    isDateSorted = true
                    
                case .avgRecents:
                    _filteredAll = getScores(sortedBy: .avgDate)
                    isDateSorted = true
                    
                case .avgOptimals:
                    _filteredAll = getOptimals(useDaily: true)
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
    
    /// Calculates the number of days between `last` and the first recorded score `Date`.
    /// Calculation defaults to the game day number for today if no `last` `Date` provided.
    ///
    /// - Parameter last: second `Date` from which to calculate the interval between it and the first recorded game `Date`.
    /// - Returns: Number of days between first game played and this.
    func getGameDayNumber(for last: Date? = nil) -> Int {
        
        let first = stats.firstPlayDate ??  "05/24/73".simpleDate
        let last = last ?? Date()
        
        return last.daysFrom(earlierDate: first) + 1
        
    }
    
    /// - Returns: `String` summary of all games played thus far.
    func played() -> String {
        
        return """
               Games:
                    #: \(getTotalGamesPlayed()) games played
                    $: \(getMoneySpent()) spent
                First: \(getFirstRecordedScore()?.friendlyDescription ?? "-na-")
                 Last: \(getLastRecordedScore()?.friendlyDescription ?? "-na-")
               
               Scores:
                 High: \(getHighscore()?.friendlyDescription ?? "-na-")
                  Low: \(getLowscore()?.friendlyDescription ?? "-na-")
                  Avg: \(getAvgScore()?.friendlyDescription ?? "-na-")
               
               """
        
    }
    
    /// Returns a summary of game(s) played on `date`.
    /// - Parameter date: `Date` for which to display game summary.
    /// - Returns: Summary of game(s) played on `date`.
    func played(_ date: Date) -> String {
        
        let defaultValue = "[Scores]\n"
        var output = getScoresFor(date).reduce(defaultValue){ $0 + " * " + $1.friendlyDescription + "\n" }
        
        if let daily = getDaily(for: date) {
            
            output  =   """
                        [Summary of Games Played \(date.simple)]
                               Played: \(daily.gamesPlayed)
                                 Rank: \(daily.rank.0.oridinalDescription) of \(daily.rank.1)
                           Avg. Score: \(daily.averageScore.delimited) [\(daily.optimality)% of \(daily.optimalScore.delimited) possible]
                           Avg. Level: \(Level.get(daily.averageLevel).name)
                            7 Day Avg: \(daily.sevenDayAverage.delimited)
                        
                        \(output)
                        
                        """
        }
        
        output = output == defaultValue ? "\(defaultValue)* none" : output
        
        return output
        
    }
    
}

// MARK: - Data Storage
extension StatManager {
    
    /// Converts `CSV` data to `Score`s and loads them into `stats`.
    func loadScores(from csv: CSV) {
        
        let rawData = csv.split(separator: "\n")
        
        for data in rawData {
            
            let rowData     = data.split(separator: ",")
            
            let dateString        = String(rowData[0])
            let date = dateString.simpleDate
            
            let scoreVal    = Int(rowData[1])!
            let level       = Int(rowData[2]) ?? -1
            
            var scores      = getScoresFor(dateString)
            let score       = Score(date: date,
                                    score: scoreVal,
                                    level: level)
            
            scores.append(score)
            
            setData(dateString, using: scores)
            
        }
        
    }
    
    /// Compiles all score data into a comma separated file format.
    /// - Important: this call gets expensive as score data grows - call async when possible.
    private func getCSV() -> CSV {
        
        // tally before collating stats in csv
        tally()
        
        var output = ""
        
        let scores = getScores(sortedBy: .date)
        
        scores.forEach{ output += $0.csv }
        
        return output
        
    }
    
    /// Saves `csv` to disk.
    func save(_ csv: CSV? = nil,
              toFile: String? = nil) {
        
        assert(!(csv.isNil && toFile.isNotNil),
               """
                Attempting to load default CSV values into
                non-default file location.
                
                Does this make sense?
                """)
        
        var csv: CSV! = csv
        
        if csv.isNil {
            
            if !saveNeeded { return /*EXIT*/ }
            else { saveNeeded = false }
            
            csv = getCSV()
            
        }
        
        do {
            
            let file = toFile ?? Configs.File.Path.currentData
            
            try csv.write(toFile: file,
                          atomically: true,
                          encoding: String.Encoding.utf8)
            
            self.csv = csv
            
            APNUtil.Utils.log("Saved data to: \(file)")
            
        } catch {
            
            APNUtil.Utils.log(error.localizedDescription)
            
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
                APNUtil.Utils.log("Backing up: \(backupFilePath)")
                save(csv, toFile: backupFilePath)
                
            } else {
                
                APNUtil.Utils.log("Loading: \(Configs.File.Path.currentData)")
                
            }
            
        }
        
        if useDefaults {
            
            // load reset data
            APNUtil.Utils.log("Loading Defaults: \(Configs.File.Path.defaultData)")
            
            let savedData   = FileManager.default.contents(atPath: Configs.File.Path.defaultData)
            csv = String(decoding: savedData!,
                         as: UTF8.self)
            
            save(csv)
            
        }
        
        self.csv = csv
        
        loadScores(from: csv)
        
        completion?()
        
    }
    
    /// Runs a series of data checks, presenting an alert at the first one that doesn't pass.
    /// - warning: this method is relatively expensive has to open and scan documentDirectory
    /// - important: this method displays an Alert and must be called in viewDidAppear.
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
    
    static func percentile(_ rank: (Int, Int)) -> Double {
        
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

extension StatManager: DataManagerConfiguratorDataSource {
    
    var gapFindableData: [GapFindable]? {
        
        var dayNumbers = [Int]()
        
        for date in stats.dates {
            
            dayNumbers.append(getGameDayNumber(for: date))
            
        }
        
        return dayNumbers
        
    }
    
    var gapFindableRange: ClosedRange<Int>? {
        
        let lbound = 1
        let ubound = getGameDayNumber()
        
        return lbound...ubound
        
    }
    
    var gapFindableStride: Int? { 1 }
    
}


// - MARK: Debug
extension StatManager {
    
    func playCountFor(_ date: Date) -> Int {
        
        getScoresFor(date).count
        
    }
    
    func threadInfo(_ caller: String, pre: String = "") {
        
        
        if !Configs.Test.shouldPrintThreadInfo { return /*EXIT*/ }
        
        let pre = pre.count > 0 ? "\n\t\(pre)" : ""
        
        print("""
                    ---\(pre)
                    \(caller)
                    \ttime: \(Date().timeIntervalSince1970.decimal(to:6))ms
                    \tisMainThread: \(Thread.isMainThread)
                    \tthread: \(Thread.current)
                    \tneedsTaly: \(stats.needsTally)
                    \ttoday count: \(playCountFor(Date()))
                """)
        
    }
    
    
    /// Generates `scoreCount` random but plausible `Score`s
    /// - Parameter count: number of random `Score`s to generate.
    /// - Returns: sorted `CSV`
    static func generateTestCSV(scoreCount count: Int) -> CSV {
        
        var scores = Set<Score>()
        
        while scores.count < count {
            
            scores.insert(Score.random(allowInvalidScores: false))
            
        }
        
        var csv = ""
        
        scores.sorted{$0.date > $1.date}.forEach{ csv += $0.csv }
        
        return csv
        
    }
    
}
