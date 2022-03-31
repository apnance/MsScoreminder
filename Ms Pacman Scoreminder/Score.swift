//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

enum ScoreType { case average, single }

struct Score {
    
    private static let levels = ["*", "$", "@", "&", "#", "¿", ")", ")2", ")3", ")4", ")5", ")6"]
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
                                     "Banana6"]
    
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
    var scoreType: ScoreType = .single
    
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
