//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

struct Score: Codable, CustomStringConvertible {
    
    static let levels = ["*", "$", "@", "&", "#", "¿", ")", ")2", ")3", ")4"]
    static let levelString = ["Cherry",
                              "Strawberry",
                              "Orange",
                              "Pretzel",
                              "Apple", "Pear",
                              "Banana",
                              "Banana2",
                              "Banana3",
                              "Banana4"]
    
    static let levelColors: [Int : UIColor] = [0 : UIColor(named: "Cherry")!,
                                               1 : UIColor(named: "Strawberry")!,
                                               2 : UIColor(named: "Orange")!,
                                               3 : UIColor(named: "Pretzel")!,
                                               4 : UIColor(named: "Apple")!,
                                               5 : UIColor(named: "Pear")!,
                                               6 : UIColor(named: "Banana")!,
                                               7 : UIColor(named: "Banana")!,
                                               8 : UIColor(named: "Banana")!,
                                               9 : UIColor(named: "Banana")!]
    
    var date: Date
    var score: Int
    var level: Int
    
    var displayScore: String { score.delimited }
    var levelString: String { Score.levels[level] }
    var levelColor: UIColor { Score.levelColors[level] ?? UIColor.cyan }
    
    var levelIconImage: UIImage { UIImage(named: "ms_icon_\(level)")! }
    
    var description: String {
        
        "\(date.simple)|\(score.delimited)|\(levelString)"
        
    }
    
}

