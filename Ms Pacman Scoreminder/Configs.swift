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
    
    struct UI {
        
        struct Shadow {
            
            static let defaultOpacity = 0.3
            
            static let defaultWidth     = 5
            static let defaultHeight    = 2
            
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
        
        /// Setting to true causes Scoreminder to replace any data on device with a copy of the default data.
        /// Doing so also causes a backup file to be written to your documents directory(viewable in
        /// iOS's Files app) before reverting to default values.
        ///
        /// - important: Set to false when not testing.
        static let shouldRevertToDefaultData = false
        
    }
    
}
