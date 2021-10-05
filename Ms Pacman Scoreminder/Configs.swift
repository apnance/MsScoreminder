//
//  Configs.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import Foundation

struct Configs {
    
    struct Archive {
        
        static var key = "MsPacManArchiveKey"
        
    }
    
    struct File {
                
        private static let basePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path + "/"
        static let path = basePath + "Current.csv"
        
        // Generates a unique backup filepath appending filename in format: 'Backup-MM.dd.yy-HH.mm.ssss.csv'
        static func generateBackupPath() -> String {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM.dd.yy-HH.mm.ssss"
            
            let date = dateFormatter.string(from: Date())
            
            return basePath + "Backup-\(date).csv"
            
        }
    }
    
    struct Test {

        /// Set to false when not testing.
        static var revertToHistoricData = false
        
    }
    
}
