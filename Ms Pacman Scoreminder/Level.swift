//
//  Level.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/8/23.
//

import UIKit
import APNUtil


/// fruit level index constants
let cherry      = 0
let strawberry  = 1
let orange      = 2
let pretzel     = 3
let apple       = 4
let pear        = 5
let banana1     = 6
let banana2     = 7
let banana3     = 8

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
            for i in cherry...levelNum {
                
                if i > cached.lastUsableIndex {
                    
                    cached.append(Level(i))
                    cumm += cached[i].optimalScore
                    cached[i].optimalScoreCummulative = cumm
                    
                    
                } else {
                    
                    cumm = cached[i].optimalScoreCummulative
                    
                }
                
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
        
        let postfix         = num > banana1 ? String(describing: num - 5) : ""
        let index           = min(num, banana1)
        
        name                = names[index] + postfix
        abbr                = levelStrings[index] + postfix
        
    }
    
    private func setDotCount() {
        
        switch num {
                
            case cherry:        dotCount = 220
            case strawberry:    dotCount = 220
            case orange:        dotCount = 240
            case pretzel:       dotCount = 240
            case apple:         dotCount = 240
            case pear:          dotCount = 238
            case banana1:        dotCount = 238
            case banana2:       dotCount = 238
            case banana3:       dotCount = 238
                
                // Repeating mazes 2 & 3
            default:    dotCount = (maze == 2 ? 238 : 234)
                
        }
        
    }
    
    private func setFuitScore() {
        
        switch num {
                
            case cherry:        fruitScore = 100
            case strawberry:    fruitScore = 200
            case orange:        fruitScore = 500
            case pretzel:       fruitScore = 700
            case apple:         fruitScore = 1000
            case pear:          fruitScore = 2000
            case banana1:        fruitScore = 5000
                
            // Note: Banana2+ returns optimal fruit score.
            default:            fruitScore = 5000
                
        }
        
    }
    
    private func setOptimalScore() {
        
        optimalScore = (2 * fruitScore) + (10 * dotCount) + powerPillsScore + ghostsScore
        
    }
    
    private func setMaze() {
        
        switch num {
                
            case cherry...strawberry:   maze = 0
            case orange...apple:        maze = 1
            case pear...banana3:        maze = 2
                
            // >8, mazes alternate at intervals of 4
            default:                    maze = ((num - 9) / 4).isEven ? 3 : 2
                
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
