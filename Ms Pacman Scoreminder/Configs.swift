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
        
        // file path
        private static let basePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path + "/"
        static let fileName = Test.forceLoadDataNamed
        static let defaultDataPath = Bundle.main.url(forResource: fileName, withExtension: "csv")!.relativePath
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
            
            basePath + generateBackupFileName()
            
        }
    }
    
    struct Test {

        /// Setting this property to the name of a file in `.documentDirectory` causes Scoreminder
        /// to replace any data on device with a copy of the that file.
        ///
        /// Doing so also causes a backup file to be written to your documents directory(viewable in
        /// iOS's Files app) before reverting to default values.
        ///
        /// - important: Set to empty string  when not testing.
        fileprivate static let forceLoadDataNamed = "TestData" //use "DefaultData", "TestData", or ""
        
        /// Flag indicating if the data loader should force load data over existing data.
        static var shouldReloadData: Bool { !forceLoadDataNamed.isEmpty }
        
    }
    
}
