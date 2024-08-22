//
//  StatManagerTests.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 8/19/24.
//

import XCTest
import UIKit
//import APNUtil
@testable import Ms_Scoreminder

//@testable import Ms_Scoreminder

@available(iOS 16.0, *)
final class StatManagerTests: XCTestCase {
    
    /// Number of times to double the startingScoreCount of 1000
    /// ```
    /// 1   = 2,000 scores
    /// 2   = 4,000
    /// 3   = 8,000
    /// 4   = 16,000
    /// 5   = 32,000
    /// 6   = 64,000
    /// 7   = 128,000
    /// 8   = 256,000
    /// 9   = 512,000
    /// 10  = 1,024,000
    /// ```
    private static let doublings            = 9
    private static let startingScoreCount   = 1000
    private static let maxRandomScoreCount  = scoresPer(doublingCount: doublings)
    
    private static func scoresPer(doublingCount: Int) -> Int {
        Int(Double(startingScoreCount) * (pow(2.0,Double(doublingCount))))
    }
    
    private static func buildData() -> [Int : CSV] {
        
        var intToCSV = [Int : CSV]()
        
        let buildTime = ContinuousClock().measure {
            
            print("BEG: Building \(maxRandomScoreCount) Random Scores.")
            
            let (_ , scoresAsCSV) = Score.random(count: maxRandomScoreCount, allowInvalidScores: false)
            
            var csv = ""
            
            var end = 0
            for i in 0...Self.doublings {
                
                let start       = end
                end             = Self.scoresPer(doublingCount: i)
                
                let subArray    = scoresAsCSV.sub(start:    start,
                                                  end:      end - 1)
                
                print("Building: \(start)\t->\t\(end)")
                
                csv = Array(subArray).reduce(""){$0 + $1}
                
                intToCSV[end] = csv
                
            }
            
        }
        
        print("END: Building \(maxRandomScoreCount) Random Scores. \(buildTime)")
        
        
        return intToCSV
        
        
    }
    
    /// Test performance time of various StatManager operations.
    func testDoublingRatios() {
        
        //        fatalError("Add some XCTAsserts to make this test meaningful")
        func process(label:String, dataCount: Int, currentDuration: Duration, previousTime: Double?) -> Double {
            
            let currentTime = currentDuration.totalSeconds
            let ratio       = previousTime.isNotNil ? (currentTime / previousTime!).roundTo(4).description : "--na--"
            
            print("\(label)\t\t\(dataCount)\t\t\(currentTime.roundTo(4))\t\t\(ratio)")
            
            return currentTime
            
        }
        
        
        let filePathString  = Configs.File.Path.generatePathForFileNamed("SAVE_TIME_TEST_FILE")
        
        let totalRunTime = ContinuousClock().measure {
            
            let countToCSV: [Int:CSV] = StatManagerTests.buildData()
            
            print("""
                    
                    ------------------------------------------------------------
                                        Doubling Ratios(x\(StatManagerTests.doublings))
                    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    Operation\tScores\t\tTime(s)\t\tTime / Previous Time
                    ------------------------------------------------------------
                    """)
            
            var prevLoadTime: Double?
            var prevTallyTime: Double?
            var prevSaveTime: Double?
            
            var dataCount       = StatManagerTests.startingScoreCount
            var data = ""
            var doublingCount = 0
            
            while dataCount <= StatManagerTests.maxRandomScoreCount {
                
                let statMan     = StatManager()
                
                data            += countToCSV[dataCount]!
                
                if doublingCount > 0 {
                    print("\nDOUBLING #\(doublingCount)")
                }
                doublingCount += 1
                
                let loadTime    = ContinuousClock().measure { statMan.loadScores(from: data)}
                prevLoadTime    = process(label: "Load",
                                          dataCount: dataCount,
                                          currentDuration: loadTime,
                                          previousTime: prevLoadTime)
                
                let tallyTime   = ContinuousClock().measure { statMan.tally() }
                prevTallyTime   = process(label: "Tally",
                                          dataCount: dataCount,
                                          currentDuration: tallyTime,
                                          previousTime: prevTallyTime)
                
                let saveTime    = ContinuousClock().measure { statMan.save(data, toFile: filePathString) }
                prevSaveTime    = process(label: "Save",
                                          dataCount: dataCount,
                                          currentDuration: saveTime,
                                          previousTime: prevSaveTime)
                
                print("\t\t\t\(statMan.stats.averagedGamesCount)*")
                
                // Double data count
                dataCount *= 2
                
            }
            
            print("------------------------------------------------------------")
            
        }
        
        let seconds = Int(totalRunTime.totalSeconds)
        let minutes = Int(totalRunTime.totalMinutes)
        
        let remainingSeconds = seconds % 60
        print("""
                    Total Run Time: \(minutes)m \(remainingSeconds)s [\(totalRunTime.totalSeconds.roundTo(4))s]
                    
                    *Averaged Scores Tallied
                    ------------------------------------------------------------
                    
                    """)
        
        // Delete test file.
        delete(fileAtURL: URL(fileURLWithPath: filePathString))
        
    }
    
    private func delete(fileAtURL url: URL) {
        
        do { try FileManager.default.removeItem(at: url) }
        catch {
            
            print("""
                    ------------------------------
                    \(#function)
                    Error deleting file\(url): \n\(error)
                    ------------------------------
                    """)
            
        }
        
    }
    
}
