//
//  StatManagerTests.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 8/19/24.
//

import XCTest
import UIKit
@testable import Ms_Scoreminder

@available(iOS 16.0, *)
final class StatManagerTests: XCTestCase {
    
    let statMan = StatManager.from("TestDataStatistics")
    
    func testAverage() {
        
        let avg = statMan.stats.avgScore!
        
        XCTAssert(73643     == avg.score,       "Expected: 68220 - Actual: \(avg.score)" )
        XCTAssert(6         == avg.level.num,   "Expected: 5 - Actual: \(avg.level.num)" )
        XCTAssert("Banana"    == avg.level.name,  "Expected: Pear - Actual: \(avg.level.name)" )
        
    }
    
    func testStdDev() {
        
        let actual = Int(statMan.stats.stdDev!)
        let expected = 24464
        
        XCTAssert(expected == actual, "Expected: \(expected) - Actual: \(actual)")
        
    }
    
}

// - MARK: Test Helpers
extension StatManager {
    
    /// Generates a `StatManager` with data loaded from `dataFileName`.csv
    /// - Parameter csvFileName: name of .csv file containing data to load
    /// - Returns: Fully loaded and ready `StatManager`
    static func from(_ csvFileName: String) -> StatManager {
        
        let path    = Bundle.main.url(forResource: csvFileName,
                                                  withExtension: "csv")!.relativePath
        
        let data    = FileManager.default.contents(atPath: path)!
        
        let csv     = String(decoding: data,
                     as: UTF8.self)
        
        let statMan = StatManager()
        statMan.loadScores(from: csv)
        statMan.tally()
        
        return statMan
        
    }
}
