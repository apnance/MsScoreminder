//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import UIKit
import APNUtil
import APNGraph

enum ScoreType {
    
    case average, single
    
    var isDeletable: Bool { return self != .average }
    
}

struct Score {
    
    private static let levels = ["*",
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
                                 ")9"]
    
    private static let levelNames = ["Cherry",
                                     "Strawberry",
                                     "Orange",
                                     "Pretzel",
                                     "Apple",
                                     "Pear",
                                     "Banana",
                                     "Banana2",
                                     "Banana3",
                                     "Banana4",
                                     "Banana5",
                                     "Banana6",
                                     "Banana7",
                                     "Banana8",
                                     "Banana9"]
    
    static var levelCount = { levelNames.count }()
    
    static func colorFor(level: Int) -> UIColor {
        
        UIColor(named: levelNames[level]) ?? UIColor.cyan
        
    }
    
    static func contrastColorFor(level: Int) -> UIColor {
        
        switch level {
            case 0,1,3,4 : return UIColor.white
            default: return UIColor.black
        }
        
    }
    
    static func stringFor(level: Int) -> String {
        
        levels[level]
        
    }
    
    static func nameFor(level: Int) -> String {
        
        levelNames[level]
        
    }
    
    static func iconFor(level: Int) -> UIImage? {
        
        UIImage(named: "ms_icon_\(level)")
        
    }
    
    var date: Date
    var score: Int
    /// Zero-based highest level attained.
    var level: Int
    
    /// The number of game scores included in average score.
    /// - note: Default value is 1 and indicates an unaveraged `Score`.
    private(set) var averagedGameCount: Int = 1
    var scoreType: ScoreType { averagedGameCount > 1 ? .average : .single }
    
    var displayScore: String { score.delimited }
    var levelString: String { Score.stringFor(level: level) }
    var levelIcon: UIImage { UIImage(named: "ms_icon_\(level)")! }
    
    var colorLight: UIColor { Score.colorFor(level: level) }
    var colorDark: UIColor { Score.contrastColorFor(level: level) }
    
}

extension Score: CustomStringConvertible {
    
    var description: String {
        
        "\(date.simple)|\(score.delimited)|\(levelString)"
        
    }
    
}

extension Score: Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        lhs.score == rhs.score
        
    }
    
}

extension Score : APNGraphable {
    
    typealias X = Date
    typealias Y = Int
    
    var x: X {
        get { self.date }
        set { self.date = newValue }
    }
    
    var y: Y {
        get { self.score }
        set { self.score = newValue }
    }
    
    var pointColor: UIColor { Score.colorFor(level: level) }
    var pointBorderColor: UIColor { .black.pointEightAlpha }
    var pointImageName: String? { "ms_graph_icon_\(level)" }
    
    init(x: Date, y: Int) {
        
        self.date   = x
        self.score  = y
        self.level  = -1
        
    }
    
    init(date: Date,
         score: Int,
         level: Int) {
        
        self.date   = date
        self.score  = score
        self.level  = level
        
    }
    
}
