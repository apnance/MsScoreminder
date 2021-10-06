//
//  Preferences.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/6/21.
//

import APNUtils

enum ScoreSortFilter: Codable {
    
    case last
    case highs
    case lows
    
    mutating func cycleNext() {
        
        switch self {
            
            case .last: self    = .highs
                
            case .highs: self   = .lows
                
            case .lows: self    = .last
            
        }
        
    }
    
    var labelText: String {
        
        switch self {
            
        case .last:     return "Recent Scores"
            
        case .highs:    return "High Scores"
            
        case .lows:     return "Low Scores"
            
        }
        
    }
    
}

/// - important: use shared singleton
class Preferences: Codable {
        
    /// singleton
    static var shared: Preferences = unarchive()
    
    /// Stores the score sorting filter
    var scoreSortFilter: ScoreSortFilter = .last { didSet{ archive() } }
    
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
