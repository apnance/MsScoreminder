//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

struct Score: Codable {
    
    private static let levels = ["*", "$", "@", "&", "#", "¿", ")", ")2", ")3", ")4", ")5", ")6"]
    private static let levelNames = ["Cherry",
                                     "Strawberry",
                                     "Orange",
                                     "Pretzel",
                                     "Apple", "Pear",
                                     "Banana",
                                     "Banana2",
                                     "Banana3",
                                     "Banana4",
                                     "Banana5",
                                     "Banana6"]
    
    static var levelCount: Int { 9 }
    
    static func colorFor(level: Int) -> UIColor {
        
        UIColor(named: levelNames[level]) ?? UIColor.cyan
        
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
    var level: Int
    
    var displayScore: String { score.delimited }
    var levelString: String { Score.stringFor(level: level) }
    var levelColor: UIColor { Score.colorFor(level: level) }
    
    var levelIcon: UIImage { UIImage(named: "ms_icon_\(level)")! }
    
}

extension Score: CustomStringConvertible {
    
    var description: String {
        
        "\(date.simple)|\(score.delimited)|\(levelString)"
        
    }
    
}
