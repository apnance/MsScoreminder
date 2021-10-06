//
//  Configs.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import Foundation

struct Configs {
    
    struct Archive {
        
        struct Keys {
            
            static let preferences = "MSScorePrefsKey"
            
        }
        
    }
    
    struct File {
                
        static let maxBackupCount = 5
        
        private static let basePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path + "/"
        static let defaultDataPath = Bundle.main.url(forResource:"DefaultData", withExtension: "csv")!.relativePath
        static let currentDataPath = basePath + "Current.csv"
        
        /// Generates a unique backup file name based on current date/time
        /// in format: 'Backup-MM.dd.yy-HH.mm.ssss.csv'
        static func generateBackupFileName() -> String {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM.dd.yy-HH.mm.ssss"
            
            let date = dateFormatter.string(from: Date())
            
            return "Backup-\(date).csv"
            
        }
        
        /// Generates a unique backup filepath appending filename
        /// in format: 'Backup-MM.dd.yy-HH.mm.ssss.csv'
        static func generateBackupFilePath() -> String {
            
            
            return basePath + generateBackupFileName()
            
        }
    }
    
    struct Test {
        
        /// Set to false when not testing.
        static let shouldRevertToDefaultData = false
        
    }
    
}
