//
//  EmailManager.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 11/9/21.
//

import UIKit

enum HTMLDestination { case email, app}

struct EmailManager {
    
    private struct Color {
        static let cherry       = "#DB0029"
        static let strawberry   = "#AA0026"
        static let pretzel      = "#A4642F"
        static let orange       = "#FB8300"
        
        static let apple        = "#DB0029"
        static let banana       = "#FEE732"
        static let pear         = "#BCF824"
        
        static let pink         = "#EF307D"
        static let blue         = "#1082C8"
        static let white        = "white"
        static let black        = "black"
        
    }
    
    /// Keeps track of the types of columnar output columnate has generated.  This is used to generate the CSS
    /// needed to accompany the HTML output.
    static private var colCounts = Set<Int>()
    
    /// Builds flex-aligned columnar HTML with column content specified in `columnText` and class
    /// overrides for each column's CSS style in `columnClassOverrides`
    static private func columnate(_ columnText: [String],
                                  _ columnClassOverrides: [String] = []) -> HTML {
        
        let cols = columnText.count
        colCounts.insert(cols)
        var spanClasses = Array(repeating: "", count: cols)
        
        for i in 0..<columnClassOverrides.count   {
            
            if i >= cols { break /*BREAK*/ }
            
            spanClasses[i] = " class =\"\(columnClassOverrides[i])\""
            
            
        }
        
        var output = "<div class=\"row\">"
        
        for (i, datum) in columnText.enumerated() {
            
            let colClass = colClassName(i + 1, of: cols)
            
            output += "<div class=\"\(colClass)\"><span\(spanClasses[i])>\(datum)</span></div>\n"
            
        }
        
        output += "</div>\n"
        
        return output
        
    }
    
    /// Returns a string representing the CSS classname to use for the column number `col` of a total of
    /// `totalCols`
    ///
    /// eg. column 1 of 3 would have class name of col1_3
    static private func colClassName(_ col: Int,
                                     of totalCols: Int) -> String {
        
        "col\(col)_\(totalCols)"
        
    }
    
    static private func spanWrap(_ content: CustomStringConvertible, withClass cssClass: String) -> HTML {
        
        var description = content.description
        
        let down    = "▼"
        let up      = "▲"
        
        if let int = Int(description) {
            
            description = int.delimited
            
            if int > 0 { description        = up + description }
            else if int < 0 { description   = down + description.replacingOccurrences(of: "-", with: "")}
            
        } else if let dub = Double(description) {
            
            if dub > 0 { description        = up + description }
            else if dub < 0 { description   = down + description.replacingOccurrences(of: "-", with: "")}
            
        }
        
        return "<span class=\"\(cssClass)\"> \(description)</span>"
        
    }
    
    /// Builds the CSS necessary to display the columnar HTML created by `columnate()`
    static private func buildColumnStyles(withFontSize fontSize: String) -> String {
        
        var output = ""
        
        for colCount in colCounts {
            
            switch colCount {
                    
                case 0: break /*do nothing*/
                    
                case 1:
                    
                    output +=   """
                                .col1_1 {
                                    flex: 100%;
                                    padding: 0px;
                                    text-align: center;
                                    color: \(Color.white);
                                    padding-left: 10px;
                                    font-size: \(fontSize);
                                    font-weight: bold;
                                
                                }
                                
                                """
                    
                default:
                    
                    for i in 1...colCount {
                        
                        let isInterrior     = (i != 1 && i != colCount)
                        let fractionalWidth = colCount > 2 ? min(100 / colCount, 20) : 0
                        let edgeWidth       = (100 - (fractionalWidth * (colCount - 2))) / 2
                        
                        let className       = colClassName(i, of: colCount)
                        let percentWidth    = isInterrior ? fractionalWidth : edgeWidth
                        let textAlign       = i == 1 ? "right" : (i == colCount ? "left" : "center")
                        let color           = i == 1 ? Color.banana : Color.white
                        let paddingLeft     = i == colCount ? "10px" : "0px"
                        let paddingRight    = i == 1 ? "10px" : "0px"
                        let font            = "bold \(fontSize) Futura"
                        
                        output +=   """
                                    .\(className) {
                                        flex: \(percentWidth)%;
                                        text-align: \(textAlign);
                                        color: \(color);
                                        padding-left: \(paddingLeft);
                                        padding-right: \(paddingRight);
                                        font: \(font);
                                    }
                                    
                                    """
                        
                    }
                    
            }
            
        }
        
        return output
        
    }
    
    static private func buildLevelSummaryHTML(using statMan: StatManager, forDate date: Date) -> HTML {
        
        var html = columnate(["LEVEL", "COUNT", "PERCENT", "TODAY"],
                             ["header", "header", "header", "header"])
        
        let dailyStats = statMan.getDaily(for: date)
        
        for (level, count) in statMan.stats.levelTally!.enumerated() {
            
            let percent = ((count.double / statMan.stats.singleGamesCount.double) * 100).roundTo(1)
            var gamesPlayedIndicator = ""
            
            if let playedCount = dailyStats?.levelsReached[level] {
                gamesPlayedIndicator = String(repeating: "●",
                                              count: playedCount)
            }
            
            html += columnate([Score.nameFor(level: level), count.description, percent.description, gamesPlayedIndicator],
                              ["","","","pacDot"])
            
        }
        
        return html
        
    }
    
    static private func buildDailyStatsHTML(using statMan: StatManager, forDate date: Date) -> HTML {
        
        func buildStreakHTML() -> HTML {
            
            if let  streaks = statMan.getStreaks(),
                    streaks.recent.isCurrent {
                
                var streak  = streaks.recent.durationDescription
                streak      += formatDelta(ints:(streaks.recent.length,
                                                 streaks.longest.length))
                
                return "\(columnate(["STREAK:", streak]))" /*EXIT*/
                
            } else { return "" /*EXIT*/ }
            
        }
        
        func formatDelta(ints:(Int,Int)? = nil, doubles:(Double,Double)? = nil) -> String {
            
            assert(!(ints.isNil && doubles.isNil),
                   "Must specify either ints or doubles and only one should be nil")
            assert(!(ints.isNotNil && doubles.isNotNil),
                   "ints or doubles must not both be nil, but only one should be non-nil")
            
            if let ints = ints {
                
                let delta = ints.0 - ints.1
                return delta == 0 ? "" : spanWrap(delta,
                                                  withClass: delta < 0 ? "down" : "up")     /*EXIT*/
                
            } else if let doubles = doubles {
                
                let delta = doubles.0 - doubles.1
                return delta == 0 ? "" : spanWrap(delta.description.rTrimTo(5),
                                                  withClass: delta < 0 ? "down" : "up")    /*EXIT*/
                
            }
            
            return "Error"
            
        }
        
        func buildIcons() -> HTML {
            
            let dailyStats = statMan.getDaily(for: date)
            var icons = ""
            
                for levelIndex in 0..<Score.levelCount {
                    
                    if let playedCount = dailyStats?.levelsReached[levelIndex] {
                        
                        for _ in 0..<playedCount {
                            
                            icons +=   getEncodedImageHTML(named:"ms_icon_\(levelIndex)",
                                                           withClass: "icon")
                            
                        }
                    }
                    
                }
            
            return "<div style=\"position:relative; margin: 0px; padding: 0px;\">\(icons)</div>"
            
        }
        
        if let dailyStats = statMan.getDailyStatsSummary(forDate: date).requested {
            
            var rank        = "\(dailyStats.rank.0)<span class=\"super\">\(dailyStats.rank.0.ordinal)</span> of \(dailyStats.rank.1)"
            var percentile  = StatManager.percentileDescription(dailyStats.rank)
            let games       = "\(dailyStats.gamesPlayed) today, \(statMan.getTotalGamesPlayed()) total"
            var avgScore    = dailyStats.averageScore.delimited
            var avgLevel    = Score.nameFor(level: dailyStats.averageLevel)
            
            if let previousStats  = statMan.getPreviousDaily(forDate: date) {
                
                rank        += formatDelta(ints:    (previousStats.rank.0,
                                                     dailyStats.rank.0))
                percentile  += formatDelta(doubles: (StatManager.percentile(dailyStats.rank),
                                                     StatManager.percentile(previousStats.rank)))
                avgScore    += formatDelta(ints:    (dailyStats.averageScore,
                                                     previousStats.averageScore))
                avgLevel    += formatDelta(ints:    (dailyStats.averageLevel,
                                                     previousStats.averageLevel))
                
            }
            
            return """
                        \(buildIcons())
                        \(columnate(["DATE:",        dailyStats.date.simple]))
                        \(columnate(["RANK:",        rank]))
                        \(columnate(["PERCENTILE:",  percentile]))
                        
                        \(columnate(["AVG SCORE:",   avgScore]))
                        \(columnate(["AVG LEVEL:",   avgLevel]))
                        \(columnate(["GAMES:",       games]))
                        \(buildStreakHTML())
                    """
            
        } else {
            
            return ""
            
        }
        
    }
    
    static private func buildHeader(forDestination dest: HTMLDestination) -> HTML {
        
        switch dest {
                
            case .email:
                
                let emailBG = getEncodedImageHTML(named:"ms_marquee_email",
                                                  withClass: "marqueeImg")
                
                return """
                        <div class="row" style="margin-top: -90px; padding-bottom: 0px;">\(emailBG)</div>
                        """
                
            case .app:
                
                return """
                        <div style="color: \(Color.banana); font-size: 70pt; text-align: center; margin: 0px;">DAILY SUMMARY</div>
                        """
                
        }
        
    }
    
    static private func buildVersion(forDestination dest: HTMLDestination) -> HTML {
        
        dest == .email ? "<br/><span class=\"version_number\">v\(Bundle.appVersion)</span>" : ""
        
    }
    
    static func buildSummaryHTML(using statMan: StatManager,
                                 forDate date: Date,
                                 andDestination dest: HTMLDestination) -> HTML {
        
        let date = date.sansTime()
        
        let levelSummaryHTML    = buildLevelSummaryHTML(using: statMan, forDate: date)
        let dailyStatsHTML      = buildDailyStatsHTML(using: statMan, forDate: date)
        
        let bgColor                 = dest == .email ? Color.blue    : "clear"
        let bodyHeight              = dest == .email ? "650px"      : "100%"
        let bodyPadding             = dest == .email ? "90px 0px 0px 0px" : "0px"
        let fontSize                = dest == .email ? "8.4pt"      : "25.5pt"
        
        let roundedBoxBorderWidth   = dest == .email ? "15px"       : "40px"
        let roundedBoxHeight        = dest == .email ? "560px"      : "100%"
        let roundedBoxWidth         = dest == .email ? "90%"        : "100%"
        let roundedBoxBorderColor   = dest == .email ? Color.banana    : Color.white
        let roundedBoxBorderRadii   = dest == .email ? "200px 200px 5px 5px" : "15px"
        
        let iconDim                 = dest == .email ? "30px" : "65px"
        
        let colStyles               = buildColumnStyles(withFontSize: fontSize)
        let mastHead                = buildHeader(forDestination: dest)
        
        let hr1                     = dest == .email ? "" : "<hr \"/>"
        let hr2                     = dest == .email ? "<br/>" : "<hr />"
        
        let version                 = buildVersion(forDestination: dest)
        
        return  """
                <meta name="color-scheme" content="only">
                <html>\
                <style>
                body {
                
                    background-color: \(bgColor);
                    font-weight: 900;
                    font-family: Futura;
                    width: 100%;
                    height: \(bodyHeight);
                    
                    padding: \(bodyPadding);
                    margin: 0px;
                
                    text-align: center;
                }
                
                hr {
                width: 80%;
                margin: 10px auto 10px auto;
                height: 10px;
                        background-color: \(Color.white);
                        border: 0 none;
                }
                
                .marqueeImg {
                
                  display: block;
                  margin-left: auto;
                  margin-right: auto;
                
                }
                
                .roundedBox {
                
                    border-style: solid;
                    border-radius: \(roundedBoxBorderRadii);
                    border-width: \(roundedBoxBorderWidth);
                    border-color: \(roundedBoxBorderColor);
                
                    background-color: \(Color.pink);
                
                    margin-left: auto;
                    margin-right: auto;
                    width: \(roundedBoxWidth);
                    height: \(roundedBoxHeight);
                    padding: 10px;
                
                }
                
                .down {
                    font-size: \(fontSize);
                    color: \(Color.apple);
                }
                
                .up {
                    font-size: \(fontSize);
                    color: \(Color.pear);
                }
                
                .header {
                    font-size: \(fontSize);
                    font-weight: bold;
                    color: \(Color.pear);
                }
                
                .pacDot {
                    font-size: \(fontSize);
                    font-weight: bold;
                    color: \(Color.white);
                }
                
                .icon {
                    width: \(iconDim);
                    height: \(iconDim);
                    margin-bottom: 10px;
                }
                
                * { box-sizing: border-box; }
                .row { display: flex; }
                
                .super { position: relative; top: -0.5em; font-size: 70%; }
                
                .version_number {
                    text-align: center;
                    font-size: \(fontSize);
                    color: \(Color.white);
                }
                
                /* Flex Column Styles */
                \(colStyles)
                </style>\
                <body>
                    <div class="roundedBox">
                    \(mastHead)
                    \(hr1)
                    \(dailyStatsHTML)
                    \(hr2)
                    \(levelSummaryHTML)
                    \(version)
                    </div>
                </body>\
                </html>
                """
        
    }
    
}

extension EmailManager {
    
    private static var stringEncodedImages = [String: String]()
    
    /// Returns an HTML formated <img> tag with 64-bit the string encoded image data built in.
    static private func getEncodedImageHTML(named: String,
                                            withClass className: String = "") -> HTML {
        
        if stringEncodedImages[named] == nil {
            
            stringEncodedImages[named] = UIImage(named: named)!.encodedAsBase64String()
            
        }
        
        let className = className.count > 0 ? "class=\"\(className)\"" : ""
        
        return  """
                <img \(className) src="data:image/png;base64, \(stringEncodedImages[named]!)" />
                """
        
    }
    
}
