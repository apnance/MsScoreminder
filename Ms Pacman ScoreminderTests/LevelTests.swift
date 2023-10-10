//
//  LevelTests.swift
//  Ms ScoreminderTests
//
//  Created by Aaron Nance on 10/9/23.
//

import XCTest
@testable import Ms_Scoreminder

final class LevelTests: XCTestCase {
    
    func testLevelName() {
        
        let expecteds = ["Cherry",
                         "Strawberry",
                         "Orange",
                         "Pretzel",
                         "Apple",
                         "Pear",
                         "Banana",
                         "Banana2",
                         "Banana3"]
        
        for (i, expected) in expecteds.enumerated() {
            
            let actual = Level.get(i).name
            XCTAssert(actual == expected, "Incorrect levelName: Expected: \(expected) - Actual: \(actual)")
            
        }
        
    }
    
    func testLevelString() {
        
        let expecteds = ["*",
                         "$",
                         "@",
                         "&",
                         "#",
                         "¿",
                         ")",
                         ")2",
                         ")3",
                         ")4",
                         ")5",
                         ")6",
                         ")7",
                         ")8",
                         ")9",
                         ")10",
                         ")11"]
        
        for (i, expected) in expecteds.enumerated() {
            
            let actual = Level.get(i).abbr
            XCTAssert(actual == expected, "Incorrect levelString: Expected: \(expected) - Actual: \(actual)")
            
        }
        
    }
    
    func testPerfectScoreCummulative() throws {
        
        let expecteds = [ 14600,
                           29400,
                           45000,
                           61000,
                           77600,
                           96180,
                           120760,
                           145340,
                           169920,
                           194460,
                           219000,
                           243540,
                           268080,
                           292660,
                           317240,
                           341820,
                           366400,
                           390940,
                           415480,
                           440020,
                           464560,
                           489140 ]
        
        for (i, expected) in expecteds.enumerated() {
            
            let actual = Level.get(i).optimalScoreCummulative
            XCTAssert(actual == expected, "Incorrect perfectScoreCummulative: Expected: \(expected) - Actual: \(actual)")
            
        }
        
    }
    
}
