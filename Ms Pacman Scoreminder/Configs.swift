//
//  Configs.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import UIKit

typealias Colors = Configs.UI.Colors

struct Configs {
    
    struct Archive {
        
        struct Keys {
            
            static let preferences = "MSScorePrefsKey"
            
        }
        
    }
    
    struct Notifications {
        
        static let title        = "Streak Alert"
        static let body         = "Your daily streak is in jeopardy!"
        static let id           = "Streak Warning"
        static let badgeNumber  = 1
        static let testMode     = false
        
        struct Time {
            
            static let hour     = 7
            static let minute   = 2
            static let second   = 15
            
        }
        
    }
    
    struct UI {
        
        struct Text {
            
            struct ScoreEditor {
                
                static let delete   = "DELETE SCORE?"
                static let edit     = "EDIT SCORE"
                static let enter    = "ENTER SCORE"
                
            }
            
        }
        
        struct Colors {
            
            static let white        = UIColor.white
            static let blue         = UIColor(named: "Blue")!
            static let pink         = UIColor(named: "Pink")!
            static let cherry       = UIColor(named: "Cherry")!
            static let strawberry   = UIColor(named: "Strawberry")!
            static let orange       = UIColor(named: "Orange")!
            static let pretzel      = UIColor(named: "Pretzel")!
            static let apple        = UIColor(named: "Apple")!
            static let pear         = UIColor(named: "Pear")!
            static let banana       = UIColor(named: "Banana")!
            
        }
        
        struct Display {
            
            static let graphPointCount = 30
            static let defaultAtomicScoreViewTextColor = UIColor(named:"Banana")!
            
        }
        
        struct Timing {
            
            struct Curtain {
                
                static let revealTime: Double   = 2.5
                static let revealDelayTime      = 0.001
                
            }
            
            struct Marquee {
                
                static let fadeDuration         = 0.3
                static let highDelay            = 5.0
                static let avgDelay             = 3.5
                static let lowDelay             = 3.5
                
            }
            
            struct Loop {
                
                static let interval             = 0.06
                
            }
            
            struct ScoreEditor {
                
                static let showDuration = 0.75
                static let hideDuration = 0.5
                
            }
            
            struct RoundViewInfo {
                
                static let fadeTime             = 0.39
                
            }
            
        }
        
        struct Shadow {
            
            static let defaultOpacity   = 0.3
            
            static let defaultWidth     = 5
            static let defaultHeight    = 2
            
        }
        
        struct Rotations {
            static let summaryView = 35.0
            static let streaksView = -summaryView
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
        static var shouldReloadData: Bool { forceLoadDataNamed.isNotNil }
        
        /// Flag that enables/disables printing thread info messages useful for debugging thread timing.
        static var shouldPrintThreadInfo: Bool = flag
    }
    
}
