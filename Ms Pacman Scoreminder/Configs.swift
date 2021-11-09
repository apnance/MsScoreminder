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

extension Configs {
    
    struct Image {
        
        /// String encoded representation of Ms Marquee image useful for inlined images in email.
        /// Generated with this code
        /// ```
        /// // generated via this code
        /// UIImagePNGRepresentation(UIImage(named: "RoriFaceHappy")!)?.base64EncodedString() ?? ""
        /// let bgImg = UIImage(named: "ms_marquee_email")!.pngData()?.base64EncodedString() ?? ""
        /// ```
        static var emailBG = """
            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
            """
    }
}

