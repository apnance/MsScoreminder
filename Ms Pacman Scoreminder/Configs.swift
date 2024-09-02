//
//  Configs.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import UIKit

typealias ColorTriplet = (UIColor, UIColor, UIColor)

struct Configs {
    
    struct Archive {
        
        struct Keys {
            
            static let preferences = "MSScorePrefsKey"
            
        }
        
    }
    
    struct Console {
        
        struct Command {
            
            static var category = "score"
            
            struct CSV {
                
                static var token    = "csv"
                static var category =  Configs.Console.Command.category
                static var helpText = "Formats all saved game data as CSV and copies them to pasteboard."
                
            }
            
            struct Played {
                
                static var token    = "played"
                static var category =  Configs.Console.Command.category
                static var helpText = """
                                        Echoes information about all recorded games played thus far.
                                        \tUsage:
                                        \t* 'played' echoes information about all recorded
                                        \t    games played thus far.
                                        \t* 'played <date>' echoes information for games played on <date>
                                        \t* 'played today' echoes information for games played today.
                                        """
                
            }
            
            struct StatLab {
                
                static var token    = "statlab"
                static var category =  Configs.Console.Command.category
                static var helpText = """
                                        Runs a battery of potentially expensive statistical
                                        \tanalyses, echoing the results.
                                        """
                
            }
            
        }
        
    }
    
    struct Notifications {
        
        static let times        = [7, 8, 12, 15, 17, 19, 20, 21, 22, 23]
        static let title        = "Streak Alert"
        static let id           = "Streak_Warning"
        static let testMode     = false
        
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
            
            struct ScoreEditor {
                
                static let border = UIColor.banana
                
                struct UIContainer {
                    
                    static let bg           = UIColor.msBlue
                    static let polkaDotsBG  = UIColor(patternImage: UIImage(named: "PolkaDotsWhiteDark")!)
                    static let border       = UIColor.banana
                    
                }
                
                struct FruitPad {
                    
                    static let bg       = UIColor.pretzel
                    
                    static let regKeys: ColorTriplet = (.msBlue, .msWhite, .banana)
                    static let plusKey: ColorTriplet = (.pretzel, .msWhite, .banana)
                    
                }
                
                struct NumPad {
                    
                    static let bg       = UIColor.msPink
                    
                    static let numKeys: ColorTriplet     = (.msBlue, .msWhite, .banana)
                    static let backKey: ColorTriplet     = (.msWhite, .pear.pointSevenAlpha, .msPink)
                    static let resetKey: ColorTriplet    = (.msWhite, .apple.pointSevenAlpha, .msPink)
                    
                }
                
            }
            
        }
        
        struct Fonts {
            
            struct ScoreEditor {
                
                static let `default` = UIFont(name: "Futura-Bold", size: 20)
                static let back      = UIFont(name: "Futura-Bold", size: 50.0)
                static let reset     = UIFont(name: "Futura-Bold", size: 50.0)
                
            }
            
            
        }
        
        struct Display {
            
            static let graphPointCount = 30
            static let defaultAtomicScoreViewTextColor = UIColor.banana
            
        }
        
        struct Timing {
            
            struct Curtain {
                
                static let revealTime: Double   = 3.25
                static let revealDelayTime      = 0.001
                
            }
            
            struct Marquee {
                
                static let fadeDuration = 0.3
                static let highDelay    = 5.0
                static let avgDelay     = 3.5
                static let lowDelay     = 3.5
                
            }
            
            struct Loop {
                
                static let interval = 0.06
                
            }
            
            struct ScoreEditor {
                
                static let showDuration = 0.75
                static let hideDuration = 0.5
                
            }
            
            struct RoundViewInfo {
                
                static let fadeTime = 0.39
                
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
            
            static let defaultData              = "DefaultData"
            static let testDataSmall            = "TestDataSmall"
            static let testDataSmallConsecutive = "TestDataSmallConsecutive"
            static let testData20k              = "TestData20k"     //generated via StatManager.generateTestCSV(scoreCount: 20000)
            static let nilData: String?         = nil
            
            static let final                    = Test.forceLoadDataNamed ?? File.Name.defaultData
            
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
            
            static func generatePathForFileNamed(_ name: String) -> String {
                
                base + name
                
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
        static var shouldPrintThreadInfo: Bool = false
    }
    
}
