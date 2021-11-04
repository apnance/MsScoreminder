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
        
        struct Name {
            
            static let defaultData      = "DefaultData"
            static let testData         = "TestData"
            static let nilData: String? = nil
            
            static let final            = Test.forceLoadDataNamed ?? File.Name.defaultData

        }
        
        
        struct Path {
            
            // file path
            private static let base = FileManager.default.urls(for: .documentDirectory,
                                                                  in: .userDomainMask).first!.path + "/"
            static let defaultData  = Bundle.main.url(forResource: Configs.File.Name.final,
                                                      withExtension: "csv")!.relativePath
            static let currentData  = base + "Current.csv"
            
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
                
                base + generateBackupFileName()
                
            }
            
        }
        
    }
    
    struct Test {
        
        // force loading data
        
        /// Setting this property to the name of a file in `.documentDirectory` causes Scoreminder
        /// to replace any data on device with a copy of the that file.
        ///
        /// Doing so also causes a backup file to be written to your documents directory(viewable in
        /// iOS's Files app) before reverting to default values.
        ///
        /// - important: Set to empty string  when not testing.
        /// - ex. use Configs.File.Name.defaultData, Configs.File.Name.testData, or Configs.File.Name.nilData to avoid force loading data
        fileprivate static let forceLoadDataNamed: String? = Configs.File.Name.nilData
        
        /// Flag indicating if the data loader should force load data over existing data.
        static var shouldReloadData: Bool { forceLoadDataNamed != nil }
        
    }
    
}
