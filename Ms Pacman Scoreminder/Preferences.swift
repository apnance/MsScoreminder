//
//  Preferences.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/6/21.
//

import APNUtils

enum ScoreSortFilter: Codable, CustomStringConvertible {
    
    case recents
    case highsHighFirst
    case highsNewFirst
    case lowsLowFirst
    case lowsNewFirst
    case avgRecents
    case avgHighsHighFirst
    case avgHighsNewFirst
    case avgLowsLowFirst
    case avgLowsNewFirst
    
    mutating func cycleNext() {
        
        switch self {
            
            // singles
            case .recents:              self = .highsHighFirst
            case .highsHighFirst:       self = .highsNewFirst
            case .highsNewFirst:        self = .lowsLowFirst
            case .lowsLowFirst:         self = .lowsNewFirst
            case .lowsNewFirst:         self = .avgRecents
            
            // averages
            case .avgRecents:           self = .avgHighsHighFirst
            case .avgHighsHighFirst:    self = .avgHighsNewFirst
            case .avgHighsNewFirst:     self = .avgLowsLowFirst
            case .avgLowsLowFirst:      self = .avgLowsNewFirst
            case .avgLowsNewFirst:      self = .recents
                
        }
        
    }
    
    var description: String {
        
        switch self {
            
            // singles
            case .recents:              return "Recent Scores"
            case .highsHighFirst:       return "Top Scores"
            case .highsNewFirst:        return "Top Scores by Date"
            case .lowsLowFirst:         return "Low Scores"
            case .lowsNewFirst:         return "Low Scores by Date"
            
            // averages
            case .avgRecents:           return "Recent Daily Averages"
            case .avgHighsHighFirst:    return "Top Daily Averages"
            case .avgHighsNewFirst:     return "Top Daily Averages by Date"
            case .avgLowsLowFirst:      return "Low Daily Averages"
            case .avgLowsNewFirst:      return "Low Daily Averages by Date"
            
        }
        
    }
    
}

/// - important: use shared singleton
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
            print("Unarchive - succeeded.")
            return archived /*EXIT*/
            
        } else {
            
            print("Unarchive - failed.")
            return Preferences() /*EXIT*/
            
        }
        
    }
    
    private func archive() {
        
        CodableArchiver.archive(self,
                                toFile: Configs.Archive.Keys.preferences,
                                inSubDir: nil)
        
    }
    
}
