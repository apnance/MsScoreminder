//
//  Preferences.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/6/21.
//

import APNUtil

enum ScoreSortFilter: Codable, CustomStringConvertible {
    
    // Note: Do not re-order Enum cases as FilterType's rawValue is used
    // for ordering various UI elements.
    enum FilterType: Int { case recents, highs, lows, optimals}
    
    case recents
    case optimals
    case highsHighFirst
    case highsNewFirst
    case lowsLowFirst
    case lowsNewFirst
    case avgRecents
    case avgOptimals
    case avgHighsHighFirst
    case avgHighsNewFirst
    case avgLowsLowFirst
    case avgLowsNewFirst
    
    var type: FilterType {
        
        switch self {
                
            case    .optimals,
                    .avgOptimals: return .optimals
                
            case    .recents,
                    .avgRecents : return .recents
                
            case    .highsHighFirst,
                    .highsNewFirst,
                    .avgHighsHighFirst,
                    .avgHighsNewFirst : return .highs
                
            case    .lowsLowFirst,
                    .lowsNewFirst,
                    .avgLowsLowFirst,
                    .avgLowsNewFirst : return .lows
                
        }
        
    }
    
    var isDateSorted : Bool {
        
        self == .highsNewFirst ||
        self == .lowsNewFirst ||
        self == .avgHighsNewFirst ||
        self == .avgLowsNewFirst
        
    }
    
    var isAverage: Bool {
        
        self == .avgRecents ||
        self == .avgOptimals ||
        self == .avgHighsHighFirst ||
        self == .avgHighsNewFirst ||
        self == .avgLowsLowFirst ||
        self == .avgLowsNewFirst
        
    }
    
    mutating func setFilter(_ type: FilterType,
                            daily: Bool,
                            dateSorted: Bool) {
        
        if daily {
            
            switch type {
                    
                case .recents :     self = .avgRecents
                    
                case .optimals :    self = .avgOptimals
                    
                case .highs :
                    
                    self = dateSorted ? .avgHighsNewFirst : .avgHighsHighFirst
                    
                case .lows:
                    
                    self = dateSorted ? .avgLowsNewFirst : .avgLowsLowFirst
                    
            }
            
        } else {
            
            switch type {
                    
                case .recents :     self = .recents
                    
                case .optimals :    self = .optimals
                    
                case .highs :
                    self = dateSorted ? .highsNewFirst : .highsHighFirst
                    
                case .lows:
                    self = dateSorted ? .lowsNewFirst : .lowsLowFirst
                    
            }
            
        }
        
    }
    
    var description: String {
        
        switch self {
                
            // singles
            case .recents:              return "Recent Scores"
            case .optimals:             return "Optimal Scores"
            case .highsHighFirst:       return "Top Scores"
            case .highsNewFirst:        return "Top Scores by Date"
            case .lowsLowFirst:         return "Low Scores"
            case .lowsNewFirst:         return "Low Scores by Date"
                
            // averages
            case .avgRecents:           return "Recent Daily Averages"
            case .avgOptimals:          return "Optimal Daily Averages"
            case .avgHighsHighFirst:    return "Top Daily Averages"
            case .avgHighsNewFirst:     return "Top Daily Averages by Date"
            case .avgLowsLowFirst:      return "Low Daily Averages"
            case .avgLowsNewFirst:      return "Low Daily Averages by Date"
                
        }
        
    }
    
}

/// - important: use `shared` singleton
class Preferences: Codable {
    
    /// singleton
    static var shared: Preferences = unarchive()
    
    /// Stores the score sorting filter
    var scoreSortFilter: ScoreSortFilter = .recents { didSet{ archive() } }
    
}

// MARK: - Archival
extension Preferences {
    
    private static func unarchive(resetArchive: Bool = false) -> Preferences {
        
        if let archived: Preferences = CodableArchiver.unarchive(file: Configs.Archive.Keys.preferences,
                                                                 inSubDir: "") {
            APNUtil.Utils.log("Unarchive - succeeded.")
            return archived /*EXIT*/
            
        } else {
            
            APNUtil.Utils.log("Unarchive - failed.")
            return Preferences() /*EXIT*/
            
        }
        
    }
    
    private func archive() {
        
        CodableArchiver.archive(self,
                                toFile: Configs.Archive.Keys.preferences,
                                inSubDir: nil)
        
    }
    
}
