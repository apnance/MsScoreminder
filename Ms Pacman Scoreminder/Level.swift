//
//  Level.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/8/23.
//

import UIKit
import APNUtil


/// Data structure for managing general level data.
/// - important: Access instances of this class through the `get` factory method.
class Level {
    
    /// Stores cached `Level` data
    private static var cached = [Level]()
    
    /// Factory method for managing creation/caching of Level objects.
    /// - Parameter levelNum: number of `Level` to get
    /// - Returns: `Level` with number `levelNum`
    static func get(_ levelNum: Int) -> Level {
        
        if levelNum > cached.lastUsableIndex {
            
            var cumm = 0
            for i in 0...levelNum {
                
                if i > cached.lastUsableIndex {
                    
                    cached.append(Level(i))
                    cumm += cached[i].optimalScore
                    cached[i].optimalScoreCummulative = cumm
                    
                    
                }
                
                // TODO: Clean Up - delete
                // print("Level(\(i)).optimalScoreCummulative = \(cached[i].optimalScoreCummulative)")
                
            }
            
        }
        
        return cached[levelNum]
        
    }
    
    let num: Int
    private(set) var maze                       = -1
    private(set) var name                       = "error"
    private(set) var abbr                       = "error"
    
    private(set) var dotCount                   = -1
    private(set) var fruitScore                 = -1
    let powerPillsScore                         = 200   // i.e. 50*4
    let ghostsScore                             = 12000 // i.e. 4* (200+400+800+1600)
    private(set) var optimalScore               = -1
    private(set) var optimalScoreCummulative    = -1
    
    var icon                                    = UIImage()
    var colorLight                              = UIColor.clear
    var colorDark                               = UIColor.clear
    
    private init(_ level:Int) {
        
        self.num = level
        setMaze()
        setDotCount()
        setStrings()
        setFuitScore()
        setOptimalScore()
        setUIElements()
        
    }
    
    private func setStrings() {
        
        let names           = ["Cherry", "Strawberry", "Orange", "Pretzel", "Apple", "Pear", "Banana"]
        let levelStrings    = ["*", "$", "@", "&", "#", "¿", ")"]
        
        assert(names.count == levelStrings.count)
        
        let postfix         = num > 6 ? String(describing: num - 5) : ""
        let index           = num > 6 ? 6 : num
        
        name                = names[index] + postfix
        abbr                = levelStrings[index] + postfix
        
    }
    
    private func setDotCount() {
        
        switch num {
            case 0:     dotCount = 220
            case 1:     dotCount = 220
            case 2:     dotCount = 240
            case 3:     dotCount = 240
            case 4:     dotCount = 240
            case 5:     dotCount = 238
            case 6:     dotCount = 238
            case 7:     dotCount = 238
            case 8:     dotCount = 238
                
                // Repeating mazes 2 & 3
            default:    dotCount = (maze == 2 ? 238 : 234)
                
        }
        
    }
    
    private func setFuitScore() {
        
        switch num {
                
            case 0:     fruitScore = 100
            case 1:     fruitScore = 200
            case 2:     fruitScore = 500
            case 3:     fruitScore = 700
            case 4:     fruitScore = 1000
            case 5:     fruitScore = 2000
            case 6:     fruitScore = 5000
                
            // Note: Banana2+ returns optimal fruit score.
            default:    fruitScore = 5000
                
        }
        
    }
    
    private func setOptimalScore() {
        
        optimalScore = (2 * fruitScore) + (10 * dotCount) + powerPillsScore + ghostsScore
        
    }
    
    private func setMaze() {
        
        switch num {
                
            case 0...1: maze = 0
            case 2...4: maze = 1
            case 5...8: maze = 2
            default:    maze = ((num - 9) / 4).isEven ? 3 : 2 // >8, mazes alternate at intervals of 4
                
        }
        
    }
    
    func setUIElements() {
        
        // color
        colorLight  = UIColor(named: name) ?? UIColor.cyan
        colorDark   = (num == 2 || num > 4) ? .black : .white
        
        // images
        icon        = UIImage(named: "ms_icon_\(num)") ?? UIImage()
        
    }
}

extension Level: Hashable {
    
    static func == (lhs: Level, rhs: Level) -> Bool { lhs.num == rhs.num }
    
    func hash(into hasher: inout Hasher) { hasher.combine(name) }
    
}
