//
//  EmailManager.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 11/9/21.
//

import Foundation

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
        
        static let pink         = "#F0317E"
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
    
    static private func spanWrap(_ content: CustomStringConvertible, withClass cssClass: String) -> String {
        
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
                        
                        let isInterrior = (i != 1 && i != colCount)
                        let fractionalWidth = colCount > 2 ? min(100/colCount, 20) : 0
                        let edgeWidth = (100 - (fractionalWidth * (colCount - 2))) / 2
                        
                        let className = colClassName(i, of: colCount)
                        let percentWidth = isInterrior ? fractionalWidth : edgeWidth
                        let textAlign = i == 1 ? "right" : (i == colCount ? "left" : "center")
                        let color = i == 1 ? Color.banana : Color.white
                        let paddingLeft = i == colCount ? "10px" : "0px"
                        let paddingRight = i == 1 ? "10px" : "0px"
                        let font = "bold \(fontSize) Futura"
                        
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
        
        func buildStreakHTML() -> String {
            
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
        
        if let dailyStats = statMan.getDailyStatsSummary(forDate: date).requested {
            
            var rank        = "\(dailyStats.rank.0.oridinalDescription) of \(dailyStats.rank.1)"
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
    
    static private func buildHeader(forDestination dest: HTMLDestination) -> String {
        
        switch dest {
            case .email:
                
                return """
                        <div class="row" style="margin-top: -90px; padding-bottom: 0px;"><img class="marqueeImg" src="data:image/png;base64, \(emailBG)" /></div>
                        """
                
            case .app:
                
                return """
                        <div style="color: \(Color.banana); font-size: 70pt; text-align: center; margin-bottom: 0px; margin-top:20px;">DAILY SUMMARY</div>
                        """
                
        }
        
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
        
        let roundedBoxBorderWidht   = dest == .email ? "15px"       : "40px"
        let roundedBoxHeight        = dest == .email ? "560px"      : "100%"
        let roundedBoxWidth         = dest == .email ? "90%"        : "100%"
        let roundedBoxBorderColor   = dest == .email ? Color.banana    : Color.white
        let roundedBoxBorderRadii   = dest == .email ? "200px 200px 5px 5px" : "5px"
        
        let colStyles               = buildColumnStyles(withFontSize: fontSize)
        let mastHead                = buildHeader(forDestination: dest)
        
        let hr1                      = dest == .email ? "" : "<hr />"
        let hr2                      = dest == .email ? "<br/>" : "<hr />"
        
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
                margin:20px auto 20px auto;
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
                    border-width: \(roundedBoxBorderWidht);
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
                
                * { box-sizing: border-box; }
                .row { display: flex; }
                
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
                    </div>
                </body>\
                </html>
                """
        
    }
    
}

extension EmailManager {
    
    static var emailBG = """
                iVBORw0KGgoAAAANSUhEUgAAAMgAAACKCAYAAADvyAX5AAABYWlDQ1BrQ0dDb2xvclNwYWNlRGlzcGxheVAzAAAokWNgYFJJLCjIYWFgYMjNKykKcndSiIiMUmB/yMAOhLwMYgwKicnFBY4BAT5AJQwwGhV8u8bACKIv64LMOiU1tUm1XsDXYqbw1YuvRJsw1aMArpTU4mQg/QeIU5MLikoYGBhTgGzl8pICELsDyBYpAjoKyJ4DYqdD2BtA7CQI+whYTUiQM5B9A8hWSM5IBJrB+API1klCEk9HYkPtBQFul8zigpzESoUAYwKuJQOUpFaUgGjn/ILKosz0jBIFR2AopSp45iXr6SgYGRiaMzCAwhyi+nMgOCwZxc4gxJrvMzDY7v////9uhJjXfgaGjUCdXDsRYhoWDAyC3AwMJ3YWJBYlgoWYgZgpLY2B4dNyBgbeSAYG4QtAPdHFacZGYHlGHicGBtZ7//9/VmNgYJ/MwPB3wv//vxf9//93MVDzHQaGA3kAFSFl7jXH0fsAAAA4ZVhJZk1NACoAAAAIAAGHaQAEAAAAAQAAABoAAAAAAAKgAgAEAAAAAQAAAMigAwAEAAAAAQAAAIoAAAAAmqAUhgAAABxpRE9UAAAAAgAAAAAAAABFAAAAKAAAAEUAAABFAAAo4Guk484AACisSURBVHgB7J0JeFXVtcdvcaLWVvOgliIpJFKRqS8QxABCAoQhzFMgYUZDqkAp+MQACgK2kFKlRbRPTC3VVplUVCyoTAIKqIEYUQpCmKcY5pkwrPf/73PWufteAhEfApZzvm9ln9x77hn2Wb+z1tp77X0CAX/xa8CvAb8GvuMauA77vxHC8nIuPyjiYDH4LA2SZQk/8xe/Bq5IDYRDUSIhELgeZ1KU8l6qE/xBcvI5MNbHzufFVL9NsibWkpzFTYxkTWwgMdVLCb4jNFx4bv7i18BlrYG7cLS+kHjrqCUSvhtl9MBr3/iOUjjeSMi8jPRoyZ6XKLIvOUzSAUpHAkJRS1IC6/7i18BlqYFkHEVGZVRVJaRro4r4XZ0A98/jyLjHqssXy1qdPba72xk52OvMqfzuUri7m5GTO7uKbOtkZMKEOJ7fYJ7QjBnJ4VaPH/uLXwOXvAaisUdZNDvBPLVZ0r3hZ5DvApSq7n49N0rBYElROLRUQN6f1Zjn9AokMGpUwLcgrAh/+c5rYLLCYbs29P8JCuMBnMEiSIJ1Jt9UObmdHS+Mx/8eGHo8BUNLWg2Fg6UCsnpJEs9lOURdNC3xkb/4NXDpayA2OTEizN8P9/+T5Y1/1KNiUkZZp3AD1qn84UIo6P7YYKTi/22pbaJk23K4S2ExhoJB98rIvp5iu1kKyNer2xpAHn200o+xPy4+IE49+H8vYQ3YiptDSyH7e4ZJDzm+u6sR2d/DPMGXQ7ErVSq9Eecx8yLOxYszFr3RRI7ktRfZ3d3bt3cMC5j1K5MkZ0FzkfyUoFjf49hbIArIN7VkF3HK/qZ+DTg1kEUXyjzNLUAKNnTxwPAU2A2SP8/uJHFx5fgUZ2ySFiaEQQN7D4wJg+Nkdy4gBBgq3n4JHwUAzJ1ZXwakVVRLJVkTal8IkJtxLC4+IE49+H8vcQ1kpfWICro6LiCEY9BDlaV31zsRtDf1QFEXh2X+2k4mhiBcFO6nR+coqV75NiM4zxyIEIzVc5Kc+MGCw0DiglGwobPMntZQmjcuY8Dof3O8rK37uAwMNJK0btHnAMJYCft+1a0LwuG7WG5l+MX/vwbUtZoQAgfdFxeQ1cvaeE9wHE6GDqomVGIbELNuuTx8+u/LC5WvV7UN/U0YILQgBKMaoOJxkgOxBox9iZlCWVFtoMRUQ2ykbpZ7PBeQTLcq9Hr+/zXj78GvAbcG6PrI+pWtAUVXObwdyo9Sg+bfj3Ke5JGRNwmF29ateyu2hyWwoDiyI0VsAWCFoQJ3an932b+tsxH7t9xXenK0B+JLdVNkS9NRsr3ZGPmq8eNmPTsxQzpH1gR4vXDcdO/Ybj8N+2y4sJHAX/wauKQ1kDZxHOIOCw5CMvf1GoK0D6O0DUpFyWt1+8h79ftLZmyi+axi1C0hkITCQRhCAVEwWBIUBWTS+BoeGAMq1RPCkQeLsanJE7IhcYRsTBwpWwELAcFVy8aVCNR9QC6pAvg7u3AN5NAdsgH5x+S6HhijKjWRHnhyU2lVchuNlOcj+5htqOBG2an0rhCWw9tSCykKigeGa0UYgGuc8WypDjIvMV2ymw73jkEwKIRkByzJrLrp5njvT6flCloQ18Wa4V6ib0EufK/9by+2Bu6NLe0BQkh2retgFNGBIgMKmyELoZx/j+viKa+CwjI9kGhamj7/sJVQnsyIkc6tKkhK57JnGza8Tcb/7ldnHFC6y6a17eWPWTUlUNuxTBn4bU7dQeYY9j65roCwpLtFCxJ5c4RkZsSGAEI4cc1fTp4cq3D46SYXqwT+9ufUgKdEGpxr7PHpwuYGkImx7WRH89GS1/RxU25sgie6JQTn/cQ0I/0DdcxvcBSZHEgGUENcsB7C5xGSng7Fzoz1thlVqa1kN8uQ7S1Hyvam2C+OQUuRZ+3fPha/Y6A+OSJZGjcoYxoACPPx3Wx+7iJdO5g4Kda9SgXlnIv2P/Br4JvWgAISEw7IotlOjDGjTi8PEEJiKyzXCQjl2cptJfqOCLn91ltcMNQVc77nNrEBJwCfUuN+/Mb53oCRiP1y3+7+8xhzFAGJArKgUn8D2cqFcLNcQFi++IyB77fuxfuAfFMt8Lc7bw1oc2iMdgyqBdH4Y1GD/t8IEAIQDSthK78DQRCQUZVahcEDF0rBcCE5n/Xg5wrIJ796uEhAPpzbiJ+/6F6tD8h5b7v/RXE1oDlRJd0N08IBeWRAZaOEnzUeIluaPWFcrAtZELUiahmCpQPIwroPCQEJfp5pYMlNHGbcq3wcY3uzkbK5KY5Fy3SOBXFas+hirak93JzbzCn1QyyIC8jL7jX5gBSnBf7336gG4rDVV3mfO+MqGOyuz02S8giEGaBvaT4Kysq4wBXXNbIVXddfjukTAoDzuQPI6zV6yQN3xYZ8P7N2GqBxWsem1OgMYNJNf8eu5r+TLU1GGfGOax2fsQvO2aSgoHVMju5IBSg9Zck7JuWdvfX+4tdAsTXA+EJjjPNtzJwpYbKh1yMOQOb+q75RQCosAVkP98dT1DBAPkAgnhPPWCRTfl+pjWQ3wrYh2wRdLAKSUSleCMZ802rFOMRpHSMgBLJvuTgZB0vzSYP/OQcQNvMy8Oc5MzeLMBd+3d0AwnL/pi4mvYXfQ3htXNSNdP7z/17zNUAoOMFC+MKecioNkwlzmB/FjkHPcrhJh1S6AUMrGgtC5d2I1iWFY0OToPJnRDtBPPZlFFbL9NjYMEiCgDBtRLfTMhGfEQ4ei8Ie8/fiHioSkC8aDQVETktZOCBqRXj+dBfd/Ssk+NdfrvUaYFxhPy1/iP/7QrKqVrot5+EHK8u8GYnn5EZ5lsMFhO5VIDrgKS2tB4Wg7Gg5Rt6u7bQgYb+myZb7pIwdXkPuiSmliimdAzWE/RuEgsIWLDbx5mUne7JwVpJkZDgtW3Tp6G4tve+3QherIGlsiAWh9RhduZnZP+FgDz47J2k16F6pJSEgFKbq8xwhYyD+4teAVwMRWBsI+ZxNt9nzm8reTclyLL+rnNrXXU4VBOUYRufZ6eVcnzKpPlqjor0nuj7ZWWZGOFZjKoLjgs1IFTncQw7tTDFSuK+bKTmxwqQ//Er69S0vXZLLyG8Gl5Epf42R9Z+1giIzfZ29344c3d5Hpjzv9NbjfFWhJT06Fm5YV3MOmqS4oK4D5pjh1cx+Nn/eXlonOflhzC42+8b+tRWOzb7MK6OlxL5pNXUpzu3U7fzye14DbKWxW2rUhfqcLoYZ7IQnqYECYBAQI4CCYKgQCirXptz20qqZGc8hDeqUkaVQSMpHtR+S937lpJPwqb3py/ZyvAAZtzMbyrjRNeR/J9SSZ/5QU56E4q5a2iJE+QlAYQGGxbop7FznZwSEVgfnbwDhPincZ8Won4SAMjk2WSjclkIwdH8nv+4GK1LbfO5lFwMMQqKgMH2GKff4rQ0J/vWX/9QaKAoM3nwTUygY6moQioPbUzxA1ILQLXGkhxnfwd+ndKgAZaroKWP5yFuMK8Pv1Of/dEkLKV3qJpn0VG2j1LQclLzP20lq+3JG8QkAQVBACIaKDcfa5R2MFaIlUlmPJMTmjSO9c+CxVZi3RTgIhgr/pwXhNgn3/SwkG5mQaLp9GCS+FUGF/act4TFGdVzgS3QhFr/TxFMEBUNLWhA5BBhcISB78zrLxlXt4H41957AfBLTmtgxAteZgq4p7VRQHNOAQYWmJVEXS92tRIxjN4rvQqJgsKQyb81NkYiIgCkJC/dhCz+bO9NMwGBKgkkxcMAiKhhaqgX8dGELDyQ7ZV8BYem6W4zLuBTVkOF84//9XtdA3E9/GhhbrlxAZs6Mk53/7uhagp5yArN8qLLpE3n/5i6yZkVrmT01XkYNrSKtWkZKrdjSUq1qhKdQHKCkbstpAETLcnZvDzmzx4GA+1r9cWsHjrUd5PTxXnJwTzc5dqiHnD7Q3ciR3Ug/x3bL5yfJkAG/hFXpJYcxGKowH24W5MQuZ/zGn8bVkFderCuFh3rJIVqCvaFyBL+hDB1UWXau7yJnMEnDiR1dTWlmM3H3p/vkNVN4zp8AeNxZI6uXcVwLYpJtqUb4/acLHPCwDd1Rf/kPqwHe1CwFY/86d2QebrwqiQJCRaVPzxihVswt0qV9WRn+8N2wFjVl6isJsvqzdgaUkiWvE1UkPokpJ3dBYRGjGMG6ApfSqYIwOJdTfWTPrlRZk9NWPpjbRJbPayqbv2gnJ/Z0NaAQiof6VJAtX3YykBAMypk9aXIALU5dO5SVrV/hOwBCUZBZEhbCIYf7yMyXGsjiuc0EM5l452MDovs8A5D1+gmBulsckci4ip/ZkEx0moD9zsTvORzhwbcXY3hguM2ytnJQGdi6REXG9Zs4YQOGuJ5EHKIWggq+CE95fr9pA8d/BGcpUUB03ik+uam4jDu4Pfed/WELeWZsjPz9udry9vR4efe1BJn+Yh159YU4yf4AM45AuadNqWcsCdcVELpObOF67mmkqR/vIxu+6CCL5jaVlyfXMTLvrcawGB2lcD+h6SMr4DIRkrMHABjOwzsnwHZ0OyDC/vbkdZfNgCAUkh4y9UXn+gf0reRZD0LC+tkHN60HWvdwPX4fCSrh+7goHJyX9i/nxBjaoaclbjohyQMILz17j1Fk/M4otXk6AwAColKAp39CfBljRY4f7uk186ovT9eKVoRKSXeLFqR3tzvNfmlFsv5US7ZvRLMx3Cvbxdq7JVnmv9lQZr3SAC1aVeU9zHQYDsiMybEyd1YjefG5eyW5dRnj8j2HVrCnfh8j/dLulLhat3mu1d4tqfKbvhUNGKfQS87zMZPGwcUiHOtWdjR9KHQhwwHhtbBVi/Ww6C3M52tZEQKy2Okj8a3I95EO95z5dJMs9HQf3ArfHjeYwnVVZH3y00Ua90RwuGq/+zEB25doHQIYx3am4gmOdIz8ZFMycF8yp4m88TJcJViGw7uw7wK0ILlSsDZZNsFdMmDhe7ZOqTXi+RgXC/vVY/NcjuUjFoGc2ofP4TIxCOe2bMalImswzd+MyahivpvzThKaYR1F5zYUumAMpKdOSZCUTlGyCLOeVPjFLWYCB/5W5cCOLvLWqw2kyX2lnXPlA2IX4MFDgqLNyFtzuzhQo2VO68yUqAPWgzuGPd2tb7uD1f3IL67WGshKQ7u9cPgrxQUjCIrjErHVRp+SuBCpVaOU8b8JBZWJJUXhOLPHUYyX/xKHyRK6mJiBcQPhOLQpCMpfJ9WSP4yqJiz7pDr9Itw/4xm1SFQ0FQWE5UG6MVB27V23ATm4tYu0blJaVrFp14WCpbpgLBl40+ps+jJZWjUPNvXyOuk2saWNYPweE1ozXuH5HNmWgl50Bw4CUpif5kEyw+1rYV2xTmxA3CG6s69WJfDPq+ga+JhWw4MDgATBcCwIbzZ9ayqtypTn6jpT8FhgKCDa3MuSqRm0Hmx5ovWgFO5EDzgAeenZe4UWhEpHK/Lhe03ks49aeD3dDPrNd/D5jaK5CkfLQVFQeBw2834EK6GAUDk3o5+EcQs/o/Wg7FrvtHIxplBAjhfAWrqQ8PrY58LrIyBsbVu3qo3QiuR+1FKmvVhPDsHFoiuoVoSAqBzc3MtYIdZXOCA8z4T7fso6rAbh4lsRpx6u2r/Dhg27OwQOtSC0IgvfTpSWTc0N9VwHKo7TUhN0exQMllQKKgJdF501ZMNnbT1AaEFmvxJvwCAcPZLLyZ/H/bcBYy3SNAhJq+bljDAWYZCO2jM97mZOLOz/03nN5IsPW3qQEAC6WasWtAkBZDUU+pMFaJVyrYfmb/F/ulcsGcRPeb4+4h7ERpChD1c3x2MHIJWcrmT/Pnd6VmT3hk4GjOOMT1wXS+FQV4tQ8Zy9ekJ9sE4orhUZ4mrETVetZvgnZmogy/Hbe3o3mzedT2tNp6CicJu1y1uaJlNH2ZwYg64UxUBBMCD87ULMe8uJ1nAEaZcUKQfwxGVnIb87iyf/1tXtTcDM1i7+ZvZr8dL711FSoeaPTMle7QFpVY0CswNvwICqMnt2M0lI+LlZ534H/LqS1xx8an83Y4E+X9HSWJwCxE2nDveSeW82QsuU08pF5e/dzemxX7SolWyCBWPJZmfubxMtGVq6pr6cYP5f9q+mQlk4K1FoQdWCcf39NxoaN5GW8AzeHXIKdUZhQC/oxyHI3CcfJqZO8Plxfof+ldVLW/I7P1hHJXwflrTnx99rbpw+DXkT9QnINBDz1HafuNpRpmBoyW0YuFMhNLcKF2+UpG/3XxrlUkBU0QhJvz5R8uLEe/CkbSMF6zsYOY5UDcKhgEwaX8/AIdLXg4P7ZiuX9pcQEMKxYmEz4foxtIoRkNdfus8DpGBzqlSrEgGwKhs4xo1z8qlKly5pznP1SjQUAJBF7znN0dNeuE92o1l4/3o0IsDFY53w2hibHN7ixE/hgBSiJY6gEApaH8Zo5npRpwREhQmduIbwPC2/l/1qJCap0R0h1oOAaJs+S95s9dfVZzdWA+4C00LsWQkViii0BFH4/8C+d4cAQlAY4HK/LFcuSpKhj6G3vUtZI7Qi/B0BYY4Uy5SUO2Xq1EZSocKPRRV66MPVPEAYp8z4e10ZMeRueWdGA1kF94vKPmdmgrEijC9oQRLql0E/TZwQNloPHqeaa+kIyHG4lQqIXouWVHgNvNnIoHDYFsSzIrSKrptlOkUtQFi/zF1zIaElsftGfEhQIVfbkpWXTd/dcbNY8omJkzRuFhU5CIaTwqGWgyUhsZt82UzK31LK3P5DU378flPjWvFpqoAQDgVFClKFluPTDzD2okywIYADmzIxvoNPewpBISTcN/tHaEEIxw7Mp/VPdBoezU81U4uOH1FNFqNpmZaE7hYBUQtirmtSXeOucV1drJTkKOndo6L5/6abrpNf3OGASkuiVo91wXUbjvMBQjDMsdAKxjpV6+G4Wk48QlDcFwItxLb1IP5yFdWAdg62ZOCoQaQpoQiq9BpoUjFU1Od23An2lzip69oEXD7yR1ISSoZrlc7ty8tBpHsUMgZhSgl89hP56O125aDbQ63WIjki2qSafxKPmQ5bcm6ssZKXkSEHNzvxztbcZPngX43lmfExkvUMOhDXdJB8uEH7GOfsdZIkjyKA/ngeYg/2V9Dl2dtT1me3k0EP/lJGPFJFRreJEb6gk/JsZBvJuWeILLl7oCyvPlj+XX+YLG/YT5bX7SezYrtLeu1YeXpiumxwA33GYPb1F7VOC1OwrrNUu9uZDJtZAQRZXcKT6ISk8PzY205QWFeQcLfrKlKXa/dUftKh9R0rwgHRJyBfPaBP0KIAYWBqf69gxcb8l7np899E7zZym46x1QdwhANChdNM2v53xMjalsEpQA0cbTD8NoBx5IBEXTsCSclHfhUBOXMAVg6ZuwQkZ1FLNAKw09LKF2MvPYSgGHFblAoGPixbY0Zj1KIj25JGydbmT4QO3GqYIU8H0iWxOiBZ7HQw8pqLAkM/IyDHt3eVVk2dPh2Tf4bES4VEAdGSdW9ZE7pdfmLjVcKjWpHUECsC5aPS0+/GeXquVlGAUCn0cyotA/b4ereb39GScDrRU8zQda2HAqKWgy1kPMbSRv2hJ5mhgHAihqQnMT4dkKQPQyzkWJFjSF2h8Hin92ACBZzrYcwyQlAIyNzpCfg8mFBIOGyhQhbmdJe8iEzZ1XY4phrlRNWObOZ4eIxktGVDj3SZA0AMJLQk2PdJ9KQrEOGlApLSvoK5Nl4fhSMZjVsIeBUOY0lcYHlebmwiL4y/x4bEH0uCCrwSC8d7cIlmBxZvEEUtgmap4nu03ztDTPlduEIoIPq7Fein4G8eHVgFMUeqZzlsC2L6ILKDcNByqITMUEI3qybEtSC0IoSCQkhYEgzbihAOFZNYWQQgR998wANkA2ZFIRgqNhxc30DrQUhgSehuCWIbbbEKrwv+T0AoBGQK4h325XDkIlu1aE0IsCYyhgPC+p8cnCrVDuDZqaj3C6v+crlqQCv93fkzG5zzBqYmTX7mPQVNiwye2id2MWM2KKokVJqzbn8HTt605PApb7sk3EZB7N04RjJvaYO+STyxOXUPpeUw2dni0RChi3V05gPe7/T3LDmwKm8O9gHYgp87rpDTZ4MBUlb85ECMh8Ds3rLtF4/Lrvsw7j0ajQ2W1djaaJjYsjZprKjwFQx78OYrunAKvF4/S1oW5oLxunt3jZSvTAMIrQ46Jrd2NX1KrBs2ZnitYthWz5G/46QWnBYpPv7nediWb9Hlq6r95QrVgKY7pD7yW6RHMGOX4yNcyYXLgvMywptqgna4GecD5AyCT95sPi0VKBsQrlORN69s40zUkASXxoKD65ujRsj668fIxtsxs+GPRsvB8f3DlN+xdIRjRjTysPBk/ygqTdamIXFxfHfZmjZIxvWrK492QDo8waHShQjGzed2kx2Vh0t+syEhcBCUbS2HhojCkQcXcAaOtQJ9JUUBQjhOMz8MOWAE40Ekce5GnCRokCAcgtwvQsv60aZ0NmyYviYbEjdrmq+XmzAhjnW/DcJXVvugoBIu96Lv1WPlb9u0Ai0uFiBc55MO3xnhoKCvPnZSOhQSfYLaFsR+QhYFyOKZzcwUPXkKCCwHYwJakwNP9ZMj0/vKiUV95OTy3h4cTAvhsQkGh8MSjpxmD0teTyg59xOL30O+avywkexAhiRjthKeP5WQJV3FMxsYvyB9ftr9sikwRvLKI87hsV3ZVAXxSIWRsr7kGNlS5zHPehCQedjnC+xLKcKCKCC0IAMfvFOSkChprAkBYWsdAWHpwsqHjcZ56sKqBbGnRtq+qoU8NdbEgwSFr7D2lytUA6mdOpWT3WGA8KbxZtIq4LyMUFnVhVEAjHWA/09l5HbsLONv9XvjgrgW5OXx8ca9YmBuLEjcSNk3IwN5YXBH9lOBLYHFodVZvSTJ5E5pjte7Mf1lTZshxnrQgqgQjNVRQ4wlISw8F4JNQGjVCpfRomCfEK5vfiXNk33zkNj4aV8j+6f3k50PPCI5NUZ7kHxccaQM7V/Vc6/oZukDguUJXh+ueR7GoLRtcbsDiILBEhLiTmFbnhNbC9kCyO9sOOx1gjJ4sGkZ+3flyoF2V0hHrtnDqqs1Pjy79zBmKBG8nWn3uo7StGEweZGpJeaGWi4XoSEgzIjVPpRzAUHAO7GX/A3v88jv0V3WVxghR97BU/Zwspzd0zlE4ah0JiCG68KnthEcgx2UnKyB7wB5AW7Ifhxze24HWTm/hbEukzOCE8g1jSsj67KRGXwI1ghyGh2MhbscxT6zL0XO7O8cIqfxGeXMgS5ycmsP2TXqN5JXEQ0FjJVQPog0Fx1VydIGhOv6QNEm8kKcu2b+MqVHtz+JXC4Tk2FyCzZTv/tGI3mgWwXPNeV+WL9mSDLjO+SxcRCX1W+iQbzfynWZsc2yISEgCgkTDG1LwmRGWhO6W2pRCAaf2jYgRsmhHMbKQMFzFz+AXnIAUj1Fdj30WwMG4SgKkKBCQVmgIMye5bF2rekqNWpESFLjsgaO4+h0Iyh0wTgrCc+B82rtWNvZgHEsnynyyNOylLRwJ1JfzhEoLpUX7hBBKVyLmVeS4AJSAMiIQVWLBYQPCbpPVHBmDxQFiJ4H4aBwFphNyFFjDpzO+GIsMODQEZenYLFoTS1ItDlYH3CXWVWu3cMFB1HBetiQUPEJBhWQloIle6XpAuWvTfEGVdGlMTfY6lgrRCBL5c6HZMJ65AKQr4cN+EaAKGQERFPLC77qjknnnH4XnocthISw0GooHOGAqJKGlmzKppVxn/BQSGNF6qOVrcyTMu81dH7CmqkVCf2tY0EIhiZ7nsGT/zj6aQgJYWFDhv0bBUQh4W9pfVjHBI1QqBWhBdHWOrfPxAcEN/1KLVkx8N3pWtHFCkLixBlUAJyY1KwanJmQ/6to4Gm7WFQMtTR/g5s1B1ZkZ6/Bchqj9IqzIKpU4eMvaDXe+Hu8PNKvijzY+y48fWs4YLixiw3HxQCikFAhC/7ykNOjDzfrILJ5FY7zuVghcdiBnmYMO8exH9ueigFXSMe3rJgNiIEErpUmO5qHDH5vxscDWAXEtSB22rw2118pXbmmjqs97LzolzhDoD0Z2nEqOZ6ge5FjNflPwdnT2XJFYUCM35mgONyCUDEK8wEclG5rblO82hl9EGg9OryGLloyxlcgp8pSnqLWT+zqiKexsw+Wx9Epd/pAb1NyvRAp70zrOLIbw3+xzhjAlqL2eaHPzuzFLJHZvWXrg0Pl6LL70QmJ/Z7nHI0CQ8HVzWQ9MPhmvEaXi5bhs8UtTX+RN2sKYxRLWGeasuM0lQetFYHkoDYOkca+NXfLvl/42F8uRw3YlZ5lQ0JAFBKCwpuo1gQnZiBh6dzc0FYsKiIBUUh2rUmSfdkY4QcwVC6krPyOIK1e0hRNvs4Q20McwusKASEYFEKyHqMZjyCjl0Nk2QxLUIrbf/j3p/E7QqIS/r39v4mxoOC8drsuuK59HuxMVThYhsIRzKbWIN+2VqzvHMxqyf1BdPGDdK2JK1h6kPAmUYKgOK0tVAo+KXGORooDRCFRy3ExgGzNbWnGouSvRZ8M0tlpQVQIBmUxJpmbiUFTghhA4fi2gBASFRuI8HUFRDsC1ZrSItAyUGw4igJErYc2ciggrHO+eoFuL+pYW7CuoEr4h2YNhFgSzpm18O1Gxr0KguK0/asC6HBdvcHhMYhaEK9E5qvCwTJc6cL/V/eKVoQDtl7APFec5nQBJoL7AE/Xt6bFm/mtOMfV3i1owkW+1uUAhEE9e9I1yEbdeY0YWhf87nyAsD6nYYpU/k4bOLi9DcgUjMDE93bsgX/95UrXgB0A3oeTyWqXdIe8+vy9pomXYz0oR/jePgSUi950Zj7nmAgm7YUDEq7wF/v/SfrrUEYq1D5Mij0bsy2OGVZVeqdESko7THk6uDJGEzaU4+jRplzs/i92+/BGgxy8Khp1JFUq3WrKKZMwaAqWg+dNsQecmRR+17Ko1fkIsz+yHo+gxYpCC0vRpt2WiaUqUyGSk4t93R0385fLVAOExG5rZ/OiAYVgfGNAoNgXq4Dh26uiERJm7eos8gpE+P/hv7/U/ysg2vw80B0mUDHKGf24ORfj3YsAhOn7VHxaCbW62mqlcNiAuM26xrXy4bhMWv8tDmNDErjrzh/Lvo3OiEG1IKuXOgHqd2lBbEgUjPOVlxqI8P0pGGy+1vEttdwBY31So03zuJ6vbUEIB0dIagOHulU2HAqI+w5E37X6Fgp7pX+Ssw0j+NSCsORoOg43JSiXwsWib083jcJ1Wg5VOK6fDwz9PFyhL/X/2mnJqUf5HhLcEClbxhmPnzkiJsR68LzVZWIGArelaIMGrYkNCF0t6wWh5l771sNUw/fmz/QP3252MiQDGO6Etv3TtTgKxT6B3mCV4hSUSkLRoJ9T+djCz8O30W3Nd8i10vHfLO3Re1wv7vjFfS/5yE2zBZZja25XaRfvTF0aWypChtxdR4YE6kjH9IoeEAoGA3Z1qdjKtRGp/3IQnYgYAHby62DMwe0/nJ2gECW4GlHye6MZ1/iJautW17HDYo6EA6L9AOxRPo2x4AoHy+IUUOFQRRox+G755/NxsmJ+MzODiX5PGLj/1zG1adbE2vIWZnn/YlkrAwebeRWSE8hOtiEp7vjFfR8CB0BZ9q82Bo4eFetIbHSELGiQJnkdkdgIWRBI895URYXXN2ZBd0ynIc/fhsMMJcZ2CgfejkpAHnR17UJwcMogf9ogt6IuVHB8BzuOGCtQvk0nkv5WS+wmZCEcCshtWN9tA6IKzI4u9ovIAbxfw7IixSogFJ9wYL9GiVYhx4tCQN6Z1sDsk6kYhJCTuY0ZVk0+fLcplK+hWdcX73CoK0E5hZa0Y+hIVFCKO35x39uATP3rvdKgzF2yMAljUpC6T0jyGgAOS56P7GPSXzRNn9flZULjWtVysDzFCbJdy0E4YtFYhe3thZD8BMJpS883dak2qOhYH/v31+w6K4MKXfSSkHB9oFK9Hwcq1v9poHzszwPla0cFytesbCSmeYVAjSZlA1WTv+UTqMofbTdLAVErso4DrCxIilVAKA3TMqj8Zl9Ucjd9hCU/0w5JuwNO3Sy+uo0Ty6EizEQJ+9GIwOPTihCS4o5f3PcKyNtv3ysDA60NGISDkBAQY0EsQDjGPh3ze/F8KJqjZtxBXAvBMJYDbtYB9NtkZlQVwlE6EPjSBeR/8btZEA6//TdkkytrUeZC3odwmwcgkRB7Ob9O2FtdY+vRuF6OPKNMhMyDZEM4xnmfK4Uo9aZtwzplHWQOJCNM+HtPfhhZ4yn8P9iSbS//+Z4j3uAeJuWxTwTl02NizDEYuDNgZ2m7W1znqDumWxxHb/VZy3po4HoMaewapLNUENrjhTicPdFMK4RtmAfl9I84Pda5mGGxb48K5vicNMHMKALYDuI4Jzi2wpWzAMeWYgFxXaCMjGgzBHdXm9GyplmGbGk1UvpH1pMpNe7HMF4MBPMkQ0ZVaiLlb47wXsVwFAOnVGQfB58lIsGyEd62a4bYSuBGJ8gvUameBBr+Wkq0HibXdxkn13d7Wkr0ek5K9HnelIEOv5PrkgYVlqjV/sQPIsoexT05ApkZ+NNHmuWLf6/dJdTEDkKlRERNQ3U4ip/YUwKU9MmhMnimBGzp/08J9MI2nSY4gqdh4AJSDtvZEhi8HPtb7o2EIxwKCMuEej8zc0QpJMfYEmUF7QSEQkAEM5Sww4yp3rQUFFthTQo6tuWsjL/uEyVLkU6ir0zT+YVDZm0EcJy4LaH+z8x8vsbtOto7BBIbDq7bxytqnS4QZXxmZcyZhfEsFiB/rtZOGpS6y4IjE8A4IyyXuLPPKxhaKhwVo9hLHivX/XczuaHNo3LT4BlScuQC+dGTH4dIyd8tE0/GLJUb8P0Njy04e/3/vHX2+j5/OR1I++PGwC9r8oEWDsqFYpj/WIrojw4O3F51RaAcnj6DV+QE0p+SQOY8S7KxbsmT8yXwhyVB4f+22NsWtf4kgLAkZuxbBpC0v73gQOJaEIWE/SGEtjemDiUkfIusDYlaEC3pWrGVR10QW0kJCD/nO0xoQbZggJF5HRqbfpH4R1FAtNSAnVaEr1ZY9xlGFwISWhBaE0JhrA8s0MUA8ub0OBkUSDKArE8abizIikaDYClKwWK0lYV14XJF1jHXzhfrsJ+E7yhRMFgStOxsPJAycH8gkU8uMVB4AACGm59YGiIlAYUtBhBC4kpgAu7PY6/vt0Che1YBck0sGhzzYu+HbDJQuE9x8zQPgYOgWHBw3YahqPUM/MaW8N8/jhugQlBwbIUka85o41opHKaEa0VI1JLsXINUdcQEtCIOKI6LdQbvV9+2uqNRKO00C7cg6mJxZGMvTKtjIKA1ugAg2ppFUPhSnvTed8rMf8YbQAjKnq+SEdPU9twsG8ii1tWCEBDGFrQgBEQhSbmpmrkG3BsJxAaEr39TOBQQ3ce8ebDcFhxcN3DActB6cN22IITlxuHvyY1D5ziCdQVDSwMIIVFQHI9iP84nBXJNLOUCZWu9aixG/0mOsuoTnYobptARUHZKmUGvSzTcrVuHzDISge0okSOXGCkz5D1T3jhykdhSchSearaM+UhKjv3UEz1eNPZVAvues+AZ82Q8iKclhe8spEIwtYJ+O+6QGRBE5dd4QtcZwPJ79jDzN8xVspVUAXn9H/UxP29N83t+Zm9zvnVnsBGs19ep8je8mpmTXK+Yj4THnhVkhTWXb/jvdf4rLXXA16S0JOkZVTfEnXotsr9EAwq+7Yov9NmDN1ppUO+VuC5e24DpfzYPIt6DW0d+EBTUod4b3qvo9EwpkzRIbo7kFEzB8Tcczcl+lJuaDJAbOo+VEukvOQ827O+GkQuNmHtDFxuzu7BeIZmQK7r8HwAAAP//oSFz+wAAQABJREFU7b0LeFXF1ce9czkJxhBMQYhIxMQgYpAGIsr9UoIQkasEEBMQiBEFFBAMIHIxAhFRi2g1oqIoXkKtVRGUm3jFC8iLUmuLUQooUi3WWt8qatf3/6/Za2efBBCt/dr3+zzPszI75+zrzPxmrVmzZrbn/Xs/k70mZ+/wBk8Sr3SFeGVrIJvFmwlhSinfIt7Ux8QbvUS8/lcJbuewEjm1vSQNXSppU5+RTByXPut5SZj1bJQcM+c5qTPneZXEuS9K4sx1kjDiZon0naqSiGtQGkAiuGZi+/6yesMtIgcK5LO9o+Tg/gL5cl+BfPtJgX735MPd9X6GDTpZ3nq5r/zjo+EinxapLFl4lv728R/dvjz2648uDOTgPrfvFZdmyQtreuoxX304PPg9vO+htnXfTy8U+bxI9u08X9Y91l3efPE8nGeEfInrUGoe99X+QjH5X1xLDpTIayuHSZ6XK1V55VHCvH5jQz/dh/up7B8mEpKdVWOk9x33oPzWaZ6nIt/rzdqkwm1KMvIxtn56VLn17pEmlG6dGknLFscFv6XimiaJPcdLg1GLJTJro9YDS7VO5JXYMdtwnzn/3mr6nzn7ZBaAN3KuDwbh8AG53kHSZNLKWlAwU5csbC1rVnZ28mhHuftX2TJvTroUFITgQWETkLoooISQJF77ksJBUCLXvSKRwbM1o2MzcyW+13iFI+IXJguK95jUf3wACSu5QcKUMHz87hAZf3Fz3fei4acEoHC7YcNECQNCKFhpmX775wvls93DZGDfNPnTWwNDgBTWqtg1K7r9/79/vkAoX/ughOE4EiAKx6cj5YOtI+XclqfKpq5To+Ao9wrkqquaKxRfoGEwqYajr7yw+RoFw+A4kQ1YXqkkT12lYCSNe9gqsZSUeLJ4UbqW2c6t+TivazSYd5T3tw+U1zeei7LsinLMDCCJRGIlEzAksZFEOUZJNSS8jkES/5+pzj/uVStZ8bySihpwOEAIRmrPsUHm5uWlyl1L2knVFpeplrku9Vs2v4XjPsuWdJYu7dPc8SNvkwRIXUgTSMqMp4WQJEGzEJCEcct1P4JSZ/7rqjV4bwYJNUhq+TqpN/U+qaisVDgMEqZhjcECZovI46lRmObmpkYBYhVbtcfHhbJ/52AZMqixpoSNWuHgvtotvx1XMzVALDXNYWnN/ak9DI53t/STVs3ry4Kz+kfBQU3Ce9+yJe+QgLyzY7zc9cRd4k1/JdAchMMaFEJCycv15KFl2Xg2aB3TQD4YQRn62ta0ru23751CNHpt9T54L5mZqapNogAhMINvCvbBfsUQfghJjG79H/yz0mvSTjxqh+ufl8jcTSp88JTJD0tmQaA6pQQtybOr8+XjXRfAjBilcnB/cdCasVU7+OfCKJFPL0JLfJH8fe+F8tgDncOZp9uRNpdp61av9Bmh1Ll2s8S17qO/xRx3gnhZnSRSfKckTn3CyfQt0nDWFmlWhsIo3SLjH7kzaP1YmAehDbRSI2Xr/Y+Ph8uTK7tLnTpxek4CwxaSFYAwWYX9Chrkn38pkg93nC8TLs5SKOTjouB324/nD8s/CA/ACgS/276HS8PAWcVkK466I49kjcJXMK3yZzkpQMWGuTW+OEuf84v9F4qJ/G2EbFmXi+MKFIz0uS+plm4wDq07zkVpUL+OCrenTT4DZQUz7i8j8AwoJ8gXe8+PErsfS198Mlsqyj1hyvx9f3uBXDQ8S89dJzFOUoZfH2gtaq46170sCZfCxPOv702sNE2Cr/7vfSoUjqt+q3B4ZesDQBqMWyptc+rrg6Z1zpeNj3Z1FdEH4x8fs/KN0EwjJIHUAOSrP48QE4LCQkI2ScvTU4Pt5EseDCAhIImTf6P7RAbOlDro91CTaIrtlJkA15eW88OQUHMVBHAYKASEfYL3fzdQTj4pWe3rQwKi9v8I+dP/DJRpV5wmhCNcka2yh+HgdgCGQfIdgITPyW2riDRV5yX3w78hOADJ8GTXqJgZZHBY2r5tH6G0nP8a8mWTApIyCv1H5PH44mxN+dz8n3Lr9bkBHGFAeB/rKvNgcv1C74lp7x4EoUBS2i/QlKDIp6PQsIyQh+7uFpyzwQCYcoBDAZm1QSFJnFQpMcmoPxNXFqvg4v7nv9rkCt9chZeLlodwAAxv5mpNqUHSC8uCh188J0f2v8OOoTOn3v9dgSxZ1E7GX9JCK7gzs0oCLUINIgfQQvmgGBxM971ToGAgo1QTUQvt3DpMvNQ81R7sQBIQhWTaGrcNKBLRyaQQEsKRCC2SPtfBkZVBDVeCfpAz7b5BRf0KFc8qMgExSKZNbqnPRfu6lgYhINA4O1/rL7OvQmt5FIB8jWfcsjFfPt+DPsdRAmKgMf1SoSzQfkCplydVNeAoSe+g92twsAwMDGqPjavPxe8FMqR/L2jV5xUQOkM8mGS9e6SjHEpgUrmKzAaJ2p9Q1NQgel5okvZt2SCmSlbGiZpGht6sHX2eU8+Laz35MMw8QEJ5fWNfvT+WZ9o5FztAoEHqhCDhb76w826fBNv4b0pjQzfj4CD1MKsUEEICyYRKx34qbFEMDKYEhRltv1tqkLBAqMJfXN1TPn1/qEJC04pwUHvcXwFTDuemFglroDUr8yU2c6hqEQPEUgODcCTOeEZNKzWv2F/CuQjGzq0lqBAlaDFL5MsPYDbBDDFIwoAsWeS8WPRuHQmQ+TNbfScgvI78dYQ8cldHeXfrAJwPGvV79FVUk/gahObTE63HRQFCYPh8YTgMEMKx6+3B0uy0xtjHmVc1AaH2YHkwn8Nm8V/fHyZ7YUYaKDSxeN4t69z1CAj7K+bxSp+6TijqhURKKEyLMGXZW/8yvXOBJE57UjWIQaKmu1+f/PrSBCk//5WQnIIbeyNy4fV/qTN747e0F6M6WfR64GHoAbJW9ku0OBRWgIfuci5UdnQTE2OlWTOnunv3TpdKwHTLLR3UVZiVkRwFFguAXi6em8Jtfkf5bDcqGgqyogIFU1ChBZE2Y6OY6P3RYwKXsRZebqkUD3UQEywRQLnDVa5SVJbFi9E/wvlMPt89Sij8v7LCVQJ23g8JyIEiFPgAuenaHAXkazx3uMXntmkm9nPks5Ho3+TJsjvwPNCGrIwH4QkLy5eANSzWMDDlMds25UuX+q3QKS9VqaRW9/PpjQ3do1y46rHCc7BBSGk/RPdLRYMWC61vkksNklqqnkXmr13nrVcHOJO242g9rrQkUw5UsQzYCNK0Yh+oAC75x5y2YOMJt67XaoB4+TPFG/UgNMQW2b2TeZkHF/sgFeYjTVZ6CHnfLPsG42Di4T4ic9GnLXtVIlevl9jsX+jv7tm6tUT6X/m5IWHsXZ8TDBVAEgCiFRBejrs7B54gdmLDgPxyPispPBip6Pz1GCJpbdz//C4sbBHZ8lVtKdeU23QF2z7hVtEAYVpQkCsNJq+G+fRSNCBo1ZYsbIdz9fELkpqjo1Z6wrEtf65s6jxDW2C2vK89B8dADUj4/xsbBuk98BlrAcIxEHTS92wfJLfMa310gPx1pLz+vDMzWAHVcYEK812AGEw8NhV5SfAJiTYAyMvKilzZ93YfPAMqcGiMg9vUmJaPhCQyY1UAB1v5hj2W6u+WxwSEANsxmqY4j+IdC3Kkcl2ljL7naa38aXM3ow+DMY6S+6L3xz2dzDImLCFICIp5DZkumO3KmJCkjVlaDYhB0vHC0Hm7FeJe7JOIDcp/+tNku2kOSxUQwoHMfnl9L604rDxWgQ4FSMoQaBq2VJDEcfdJKvzfOejQU/CEqkWalsF0Q2bGYuDPJBWtIzPPCs9pkZJAi6x+vIW2fixoahCCQs3BzqLbly0e+xsdcQ7nqqwqKVU4CAnlwzPOlV8XDVRNQm2y7232iZxG4TbvjwVpz2cawnmxCuWTPxTI7QvPPCpA/gmtaoDwvOyb7cb4CQGxPKTmNaEmoQeQx5izgoD0PzdNcloly+IFravBAByf7wZ0IUCmjyFMJTB5nJcqDQN+LANqD80z/o/7COev9UHYUdfOenZv8SiEJD1Hy4jlRCEg2tlOpemGa5kG4XbDU/W71m2gubDv6g03Il/ZH3HeQHvesKWQXniL0yAExBdv6HR3bp7T6zoJ16n5CXcFav72b/3/FK9Z578bGNQgiTPWHCQYuKqUluZqJbQWgXa6s9U5CuzMrHFjnAcqUho9SBSLVocSYcH5mc1UIUEBGkya+t6OJesXasWl5jAtwopcigEsM7VSfHclNUcYEMJBOVBeCtt9smoOwsFO7ofQIB/6GuQ1AEIXKTUHz02Tgm5eij0nwSAkPwQQgQahicX8owZhZSzAIONkjMTfvbgttF032fRknvz6vk7yq0W5cuW4ZoG7mccQEt5TWPicBMOEgPz+xd7SMgP50vJyBYGag0JQCAfz1aAJw2GVlWCYm9srqRRv2C2ukgIUQhEWhUIrL67HsqJ5hf9PBiCV0CAF2E4uceXMcSjLR6a6jfu36/K4uAEz1MQKALkJEF65XLwTm7l78Ly3sN89kP4Q/9Mt7EyyL//t6dPe8LnSZNaaahm+BD7yY3Gj8TJtYiv/AUvkj6/2006ba3nZahdoq4Q7hLYokGTAYMLCaRGCIHLdZgz4bUY4CYBB6sG7Qknwpf9VdwnFy6uUdevKQxU/+jqZGAz0Uktk4x3Qarj+gXUlsveCGQrF1qklMicdg2m5DMVwtvuC+oOkBHCU5MKNuZ39Gnh8nhop78OuLjhjmLzva5FpE1tqwVgfS8ND2LdAh/mf8Er9DZ3YO286U75Bo0AxDROkH9O164StJj1j5/VuAlsf14Q7+W8fXCBbn8MI9JKzFAgOqjZvnqTXbN06WUYMSZebynJk2/N9kN/OzfvtJ0MRKjMUITMYl9g3MhA+w7rKXD22bU6KwpF4xcP6P8eF1P3NSARIXKtzxItP0MFTVtyyWyuQf+7Ypkn19RiWX1IOxpgQpcBtTac/IcfOf0XFG3e3+75uQ5e2yJcmxxyn2+1/liF78q+VVa3OhzZpLS0Iz6ilzvStGor8jnbo7N7RD4Oyme48bITZeLKe0BlExxC9phx748Biu8HiNWmxBfe0EvIf+Tzt9b4MFfXxajgICgAhHMtu66RwsAXY/84w+WwXNMa+USosJIrrQ2QGYIQB0Qf3IakJiIHB1IPJ1PbiexUO5IIUpbfBeXsBPpgS/nWqr0U/frVpRTjeb1GmUHRJOdXB4QNCOHg+yjp4Y3gOQrLvwgnyflGh3A5INjw3Bt+XwE3pHA3WUTdACMC3MIH+AS/c8tvO1vS7APnrn4aigUlUSMxb9uUnqPTwMpkwTuzz3QXy1/ddqlD4Zhe3CYWCsXekppYPBGXdugqMRaXoc7Hfl4l+n4XgBHBgjIixa3x2xq+djIpICUbSU+H8wG+EJAwKvyMsBgdT79zLdV/PAME+BshlmZ0VkKr86TKEni4AQkjUJQxrYc3Wy6LKkM9BSGZP6+rOyXAhQhL2mmK7EYBJLX1cjh33gHit8z/FfW2HnAmxT5xt/Lhpt0BNXaCEAo4oQHrPlZYtj4XbDuaL3+d46+V+CggrEgGxVoFq2xuNVh8xPfXKXgogOXkWWpErHpEFkCEQr+1wqVO0KNAe1CJhQDIBCKHoUj9DlrV2pp26KWEGhSHR66FwCCUzev/2AQrH7u6zZFmz0dI0sb4UNWwvG1tO1cHMxmmuhZ4/w+3PYz67Y4xUZZYqIBtCgBAMZDQahQ763OGBu29QYQnFQ3e2V01yqJF0ao///RCeMuTZG8/Clue57sC5oD0ICQGhFqFwm+EvDKQ0IRRhIRwH9yMOzNcin+waq2D0vxUtLCpeJsxZFfT7CAmvp9rD1xwM7iQ0/D7h4jtUy2h/BK1290EXI59H62/8ndIeeX9V8566ndZrYgCIB03itfyFDAjBcWpo+6kOY6MBgfYgJAYI73XJ+mtk/242RK5RdWmJPPcUtA6vT0j8iA0bWiAchMRA8QZeyn0JyaWQ8OdHBMXgOKVDQ1xhjzf+ToUjAARw4HuZNKlJVNgFNYiB8eX+AYj9qXCaA2CYlqDmSJziuwIxFsHWpApgaKuC7eNw3uSzBoYgcebV8exwI0ObJmF/mEUGSB7OkZ49GR3xatcvM5ZwmAaheVWVWi4lfkUgILx/CuGwEX8btzE4dnedHAAydfFIFBzGBfCMDJE4rxfMImzTrApDQihW3tNRDuxEOMohQk3MvGK68Bpnrr31KsYGQoAE2sMHhFrEJKxB2HknGF9Ae2yBx4+mUduF8CKhsjWmtsV2AIgPShgOjVUbNk/zISb1BAWHcFCDNGyeJ8MunYa8LldI5jTvL5QtyPvHOjhPWCb6bKZBCMjZx2bo7zNhWln+Mr0tp0DheLcXw1+mywJqEKRqZqk22SJZ5c/ofZdUrJMdb09WSKhBlt+Rr4BkZvrmFs7XCH2QJuiLmBgcTL0b1op3+WLxGmkMHUEZBbHPjwiJO+XC2CEL0Bd4TSJzXtI0yR/rSKRdiJutKGfnHJ6kXSNVWDl3/3GylOJBWVCR6a9J+vwNkjILFRyZnzZkvjSAdyMTlZ3HP4AWalOHqbqdhNYp5gzXaY1DmEg8RsWtD5IOzRMZd6+Uwi5mobGweDylaXqypjrg6GuzqjcGSKecBnIA93OgAv0MALKiR4EsPH2AtK7XRF7uNFm2d5uusFEr8Tz39/HjmKA5glDxLqUyBC7UBV6+LCih67lAgye5/8bHMI6C633JhsGXb/5SKL9Z3gmj/hhAw29hE4xmGKHi9+zD8BzFhSfJF9AoJsy/P7zyC/lkZ9ixUN2iWod82+bhQiEUw251blbm96nnoHLmogJDdJtmiW++Mq2DskycjekBc+FkQeq18fMxo602QARkZedxUpzVV7bmw/XdE3kRkt395srjOWP03scXZWkZ87rJl66SgtTMIN+2tZ4llLc7wKxFeYWlkB4wjL9kssOPPIidvkGSALT2G3Euno/1p/Tmh/R37kNJyJ8saeffLklt4cnKxDNSWB9Dz2eaxYNmqRH4iFPo5wd7ucIjk9k41UKIxF/5RDUghARuU0JCISQEg4CYsCVLnfmaPmQGPRxlm1DJQ4JzpsNPTlB4fmYcIeF2JlonQmGQxCNcROeQoP9BQBgtfMOJvfSYsOo3QKzCfoW+ACvhVZeeLttXFsi+i2bJ7rPLZO+5c+WjXvPl4qYd5O6cC+XT/IWy0W8Nef1ShKyEC3KjD+6q0zDiez4qilcqc65qrZBwf24bGJbyuo8jqHLP7+D5OgIgNNF4judXO1cnAeH+BINmY9KpV0na6JUyY2J3KYeHkDJu7ADJGT5Zj+P8FvU8+RWKlYrnIxRTJ6Rgf7ediu/U0+iDQigUEDZ6E1yHnccpKGi0woBoXFcIDoJCQCoy3WBk7y6o6P71awISzsea24cDJBHlzPrSAAOEPC8b10xAkcn7a4iBxFEwAX2oaCHQlOZzqullkFCLhIUer7P7ad7gOe3zvSKDw2DwBBdA9qi/GSdXzUEwfKmHjKZgH1m5jGZNCSI182X1iu6y4wU3EERACIeCYnDwAWh34jhqjwh85TOaoUUOAZKOyho3dpnENO+o+8WNvs21DgYI3LYsHMtw0yIGCCss4TBAXlrdSzgPgmBQCAkBmd3cmQDv9pgdBQjvjeckGHbuAA5oEkJSiXEEgsgQfO7/x9dd2EkYkI1P9JA/vTmwFiA6eg4ITHswhN40hwFy96IshYMVlSEa6lZlpYBkTb9HJ37xuoSD+2TPc5WJ3xWjX/XxsktRJk7jHNw5XNZjhFshwe/s5AYaBIDEXnCDPgOPJSBswXlOz8uUjOQc6ZHWVarOxHOjtTctsqJFoRAMag/VIDCzDJKwBrEyOpQGKeH1cM6Ww27R60cQJEkNQkCSMLmOgBAUWh7qKiYcOEZBQWp9S/ecJQ4SnhPPR7MrCpCwW3jiSxYZ/L3dwISkL2SD0kbqeGKIgWEmFmNszLyiuqcG0QzmDaIQw3DUAqRfmZpX1CA8phJmQBiQoCB5Lkhsz8uiNciUp6MA4bGvdZigwn5JATrrv38FgZFsuQHKvt8PVrOqJiDUHicdkyoEhMdRi8xBx5P9m+BZcH2CopqDcNQAhKYW973x2jP0emFAXsOA6aEAOagBjUXaweex5gkLQ1Jawnso0IrKykooei+6RVMDJAlanIBQGs7aLD3glVsJ58MBeuUw8GmAWAV6D2M+lreRib9W84omltcH5gnuw+PAHk0suLlVa+DZ+Hw3PbZA8npmyn3eEAdJBkJQ5sCRwRATX6q2ZErRgiKFJOu867Q8NzefoQ1JBVz6FQUFsil9iv5vsBggbWHCReo3dmD4gNAUNyEsCWhMKXV5n75YpIU934GqYTD1nbfOazJYUkehz2xaxK/H2uBP3FyMc/DDvshRaxHcr/cHL28EKvgidZlZp4cegnqgmVAwpZB87K/CAR3erP4P86d92UNSn/vMeUGOQZqANILpsCrzXpWYDoUSGTRdYvtM1AJ7AhXzo37Xyss9rgjOmRHyuXu5eYgwXYVK8DRGxTfq9uLeJfJhSHZjgI/Cgq1AxVqycEJg7lG7VZTmKQA23vF+z1nyhx5Xy1vdS2VXz9nyHmT3OXPlz/nzpbIN8sB/tiWtBsvH+O4AIAwLQ1G2veDGVjhTjvvbmIj1L3a8cB4qGFzPAPVLuFsP7qfLeyQ61MXq1OAxHE/h74yMDcvOrf3gcMAINTQlW/R6aFXDovfXb5p40ACUpFJoF5xPYca9VmWWwwM3rgYk1YNvmai0mVNXSiY8iNzmsRbOTrPvW0RS/xMzE7/5BPf22UWyv6qPlJSmSpuUdCnNzJPd210EQrVpXSDPbUSfBCZRJq5fgfxhnjN4kS7/TzC5aje8iByPKS/IU43u0ZtmguiIREBhko5tStpUxNNBrCHQUX/c6/L0vrKtA/pGLJctNO2r+2fvYUB43pwWrgytb2KgMOqclpHnHQM56s9aA8PjwBqEUJhQXTkooEZxcxS2RISCao6AUNQWrFwn9SfeIxnXPidxAINwRAECUGLaIjOGl2Eco0TPQ4/Iu31mqjzcvrpyFqe3l61ovQtQIB4qAOEIAJmMOdfonH1IAShvI4bKICEgHrTImpXjcE9jVbqfUxsQQrK3F0bO865RQAgJ5Xfdp8vAE1rpc/727ItrAcL7KihIRQfche8TFOaJuXwNkHc29xNKTUAIrPU9bE5JGA7dRoETkqyMFpLSd45rnHxIPJozLIdJvwkAYf7wOzNpdnfFcwGSfRfOwEBntcvUXN86YEg40OgREI7D8HgGmPL+v8YMxS/hYmZkAFOrgIvvcA2hAWJ9Tv5OQLoXzpWLpsxQMJwns7pfavvS4hh/ebbC0bt/umRhjCaxK6bfojGtCYjeH+8xJOx3lcL847MSkk2IYN7K8KYQJLxWAAmODTQJBxbTTjmAZ20KOarPIq9noUJhcDCl9iAY6jLjKCUyLysjBUB0RMXLVxiib8gRPPXe1UcGBBoktmsxvB23HxIQgrKx+zhZiQ67tdgL6anyAWnG2CyYEKUE5BXAgZSQEI4NWeM0ZbQtNUjvHuzIQtOVAHpARi+VaZCdeTMVDMJBUAwOS/f2ulbOaXia5NQ7UdZ1QAEAVArhYF4YHMwDbjPshC2wVfhv4cWi9njzOS624DSIaQ9WEJ6Diz9wf2qefb/nACA8W6ZJ/MImJOwLJGPBCjVr/UlMnmmPWc8pJJnIny71Tw00CAExISgHYHIRDjZovPbhxLQg+0lBxDEgCZf1xvXt1GtJSEyD7GJ8GrTH8gdNa7kxMEJCoQvaxEBZshh9TGgQQpJefKfUQ18jAnOKkJgGSRr6EOpJhYbEmEOC2oQNtGkQbRS8cln7SHeE2wxQ4TXWPPoL95w1Aclq+3c8f1PIUX3WeoXopPmaw1IdkVQwBsukwQwtJxRHmIOMAjU4aGLRvDLtEaVBAEjc4Gul3sR7o0ysTwfOVzOLphbF4GBKWAhIy/nIvOmPSSlipyyTmRKSFcmFGob++W43L8F+H188EZlUKg1bQQshU9nHICQfAACCQUBqapAPe18nL3S6Qjr+zJlOPC4slRXRKp2Vx8K0w4Dsw1yL19fmC2EhHBTeF8dZeD5rte3cZyJI8/UNcOsSEh8QpksWYhQZ+UATS/ftjPzwwbC0ga9BigAwKwzheKzDGLkXY0vU0Buyx6jpaZr+vltaCoUmj4WhhDUg4aD2YKpmln8/NLUo+fPREhdUasoxC8JRDlez3fehtIcBwtTKh5BQmzC8nnAko1NugBAMeqfWVWaq/PL65pKJECBKTnqKQkLtweel2UcP3yOIOKZse6GfannNLwAVaBCaWgxJ8bybIPx8Z0d9uzdlrRyHoENKPUxUicB7NL64FQrGhYbbQx8qPYD5449g+Zw8AJY0/dfSugwaZOZjkghTKiwJ174o1YL4KkaO+v2YrKbJWngVsejMpTrZgkptUopYKh1tLX9UUy5JE76XNStRYJjOa9/tR0zPAZ27USDvvT0BCwO4Ct6i/slawfKQrm07QD44f2YgVefDT+/LKlQqZJxKJLubJHa8QDM1Z9hgoWx7C+EQ0ApmShEK7s+5EbZKyNefFMpnfxoqv13eWbjN/gfli72FUoC4Ku5vXrdVbQvllc5TZTqmyvJ7dowJ1RcfoEHCdTavdmEtjHbW+2KLSMHod5AiFKRL01aysfOlqDBwJqDShF3gjH5eB03LwEzm07efjg5E/jFK1j45SLa+4BrAA7tGRY1kc8CuEpV/NMZZcsxbdvWz0oT3gJTC6QXPW2SuH09VVYX78MXKxtKv9mEKNUT+MkrT3QjLTy+FCQ2hOdW7R1vUwa4BSAbUwa3jJCc7xeVDXZQRBXn2998WY5D1AvnnJ8Plmz8VApDOMmFcsv6WisbjGNRPE/axNR/b9umA9Ds/UYAkj7lND46OfHXm084dsIshHOMgFGwxcnHhllPvUyjSGYaCm/luQF6MAoTuwkq0ZG9shpZCR46y44WRcBsXwm2MQbByhLf7cDCtwIAfobDM5uh5SWntVt0gKZ+B0ARAcSIFmYkcUVnU+FQFZRFgWdD4TBUbyec+xw67To4re1HFvHnFj90psmewwmGAPPvkOXo+W2uKkBAKCidN7dkxSDvmBITmFTVI0RBnyxMOasmdmDdOBwMDJek6JhgEhKD8absDh/dUr8OwaigMEnw/pxUcAgoG4aBHbqrek8VNEZDtfScoJDS1CAUh+XrvGE0JBSFhReQ285bhHjNXsFECCL6kwVtGOR5Q1CUkkEyITStYveouhalo+T3amKl7Ft6n9jeukqn3/1re47WpjXwwAlDwXQXmrzQYcp8CQrOyqjOeZQKktFS+WDlR7433N+PyZvpsLU5sqOmCE/PlzxMvl6+2jFRACInVjbt/lSWRjBycsxoQguINBSS5fad8Jx3YYW1NDcKCoPZY8tQcGb/slyrtb34Gg3RQ8X5GEYqwePmXY36Aa+k4kFdnwdbDahDv2ld1pRO9jrkL8eDWShwqDS9kRtXOUHZO0iEo7JATkB1bh6tsXI9K52sQZlRFOUyl8xfKiaf9QjOUrsJsQOFd8WC1QHvoRCOA0gLxYClX/jqAg5AYIEufnxsAYlqE5lXJsPRAexAQi7O6/YYzVYvwmcJmFsdQ+Px7f4GxGQgBoSzLGqVTTwmHhaP8fQ+mEfvaQ1MDgym8P13apsne9qWyr7+DwzQIx3BqAkJI3imaKH97pkS+eqc40CKE4pEVdDqwHPI0zMNMJ49h6XDFMrzdALE1ycKdZ0JCTULRcKB5j0tTX/h/G0DKvsNS9IMMDEtZTi9i5mNSmzJJuwTXM0Aw87OKgj7Gx8VwGwMi5lsLz8HB7VVnj5JdLaer/HXJWNUgBghTXVctb4Q0DkHCOu/lnvcbHP+dn7Xehbf8Xc0rTJJnmtiJJgbMAHRus6Y/qtJ7LDqWnMbJyUp9C6TZ6PkqDbG+FK5QS+LHr5DEa3Eu39Qy88qDqZWGCkeziprD/Oifwy4Ni0Hy2S6oTi00eD4e+aV0n3yrapPec+6VnMn3qHDbwGWaVnyflFdU28OXFDXQsZkTu4ytvk/AkY0KZsJQ+xZ45hYEBdumOSw1QNS88jUIAbHBPhe/Vb3ohAFy323thJCEAaGb18ZPtneeHGgQAvIUbGrm5wc7BgRmFrVIOUJ5+H0ACOGgiYXvqtYhjAamE0f4d5+KwMr6ToNQiziPnisfmlgE5NWu4+R1b6q83WaSgkJNQkDKy/Nk9fPQAGh4ND8JRs+rqvOM5cxJUhjnSoDW8CbAYhgIiwMakA0WwTBgCIZpD3rdDA5Lf31vlygtwoq847Ve6LSXVANyDp5pAATpvh7oLwISPu/uDIatIPTnxFb6PwHZmz9FZedx12i6751qk5tahMdpCIsPiQ/IR/j+Oz83eD2nwD7bIsdcvUZTjnFkZaShA7ZBkjHMnwWvQvbMxyWpdc/ozGKG+RLXbawkXHIPFmi7XWLPHi4xrftJwswN6HdgfSMKx0MoOFcmUg5G0UfO1qqmHKiqrU2WLB6m6petCwshZ8i6KGEBpYy5X1rOXa1mHwuYldAqYgrmPRzrB+TV6TpSIohijczGcqUUbDN4j88SwT4M3jNnhaXdOh0vc0qzca/O3LRFCqzD/QHNKEy1tYXdvjqATi5kzIgMWf9kD513Ts8QO75cMYWmVgYaiU1tXSdzFwL49mGexLOdxut9vP3SubjWRdBKF2hqHWkbD7AFEDiYWKULwaG/hQgGE+HYAGTtlEF6vubJrsVtn5ohPRo0l4JcmDCIS9vXfxbOz/wukN5jJ2ijmDIFMVoI9UlEI8c80XXFEpPEo/jlbROnFsw9Uyd7VZSnSve+0NCAkBJpeL6kY25JMUba+Zx6XEpDP5KYK56co9e0/GTKDnls1zKphxF17h/2ZLJPRY/X8hyE+2CbgNDhwv2YvpNfpsLJbtzenQOTtdI9l3nu4qc+9nVk/isHKQpIIwUMp9DPYQIYGzeeYoB4AKQxW6bRi9BJaooHyIPnCqEUqGwEhBP7cSqJpCGYsF4j8Y6pJ7HdxkjsOVjac9azWE4Hc9RRuZgGYNQApAnhACRD+ufJB7tY2aoB2bptivS49TGVApBuQrcul/QZf/kguARhj7PTnnuHAuLSU9TLxhU4uExNsxlovfgc+ixLdLrtcbivY/35DgQl8bpXEYuEZUohuu1PIGKodxiQ+MswaMrBLDw3IbECNUDKpraUYXBTGhiWEo5dbw+Uvvlp8tmHwxQKwvFdgDyNcHBea8u6aEBeWtVHw0vYODhI3BhGl/b1EQvWXA4wKNKHN5xa5UiMjZfKM0fLTdkDpV/aGVrBCAfl4Dbnms3qO1kazGCwoL9sEjxlsY1P0/vxUhD53BB9OUDC1RB5j5zJqPPnsWgEIeNU5G0bz1dhA2DSg7Fa0M4Ms4/E1lNhA7lk/QLZicaQsnV9a5SpWwWFgKSn8hgHCd3r85rDK+UHqNYEhPu9mjVF3uo8S9YhBIhCbUOh145rhXl1kiVyzXqFIwDE88Ia5LCAdPA6jt6t2gOA0NfuXbFcNQjhYAVes/IsSUdoesqEX+tNxya7DIo5/mSJRwh7bPuhmMl1pkRG3OIgOQIgqj0A3Ihf0QSKhkPVOn5j2rp4hWQNRXgFKry6mLe5QmBBrPltoRTP9ADIKbJ0xSk4D9UpWwsu2ZOt4zUKB917CMdgbE4YkLpYlpRQKBw+INQczGjOtAsDckzfEXLiid5y/FYS1iCshIQk+9QUHRNgyPn/YgkfA4Rh69Qcd2DKLLdtXEEBweg0K48WbIcp2iKaBqkNCBeOGIgBx5kKRhgQBjHyHBSOTj8yJ1+2PtpPhWBoxfB/L2jcWvb0vFbubX0hopenKRi7c8rk48tnaL7t3AGzGhU0vew1hUQ1iL/wnl6jGSpwyw56rZSURE1tjSxd8cTPfysHg2Mh+pg83uag6LnYX/XLOQsNISV5olv3l3BQkobM0ON0fxxPN+62rnTLU3s4DcLQIM4J0tF47BNe33n/jIk6kE3nBM8Rlz/+G9MehwHkCNG9J5zwUWBeAZBMgELiCYZVYu2wwfYkHDUBiZ++VmI7jlIT67s0yPG+BqFb+LcvXKVaZMmT1wcZphmH+RoclOSD2bpMlvHVKecKEIzJsu31fIWIg5h2nGUs4dA+RUiD1AUEEQOE5hUg0ammuB4nDtHkMtOq7s9/Lt26eXk4X25NQD7ZiY4+jtH+BwAxOJgSCsLx1qsYKAwDAjOLYRxbsVAcj7UCrwlItYnlAOHKLtQcBkgYjiJMv2VHdk56T+mSggqD85qUI0yH8i5seMptZ2BOBkCh5qCJ9dniKQrIkmVj0LdExCzKn1pEAWEUtZ2LGoTi/28mFv8fNjhD7l7UVWXelLZwYyPI0cwqO54pTCw9Hk4cA8NA0TAmHw41seANtaDEHvUx8zMAoxoQ54xwsXeEI6w5bZsahNeMze7+bS1AOo/6u5eW0w2/83PE8ZAXvJLFQaXQyoEAwnDlfA9rKA3ukaFeCAt4YxrrV8AG/a9BJefiYE+opGBQKyw2aBiLAcRUdNzrwJOVOPPZQJJxXEKXUMAjzl0/NUEfrqQoUyuUtUpMmQF0VwYxYCwAX9JoCmA7bvBsiQcY8ajwTPm/fu9rCYJAoG2h61iE7eu+BARRBCoNmr/n3azRnwX0oFjGhzvoLtgQfn1/9PlrrEbyxV54z27M1WmynAX4Beaqf/VnuG6Ryl8vUrc2gyprFry5Z998pTdcvSM0yvcgJlUREFYmLmBB6ZKWIU3RWG3Mxzq356DTShk+SyrgRGmYmKxjPzZoaC3uW7DbK89GpxdpVXuEokCsweFSSXTRp+HcKYh507k/MLFimndy+XpM3SB/vbiIbqcjqJNi+V4zZTwdKze/j+09SYXbMdk9oL0xFjb7JTl+7gsqVj80xesrWJdUO2B/aooPe18rf8y7WnadMzuQPyKWbh/6GzNP6IkVaeAgefJS+XZXtYvXns36iWmjGdjJuK6NmFC1HfLms7gfc/UeEhBG7/IzpxYgE9Hy4uZo3rgLlcrU4jYKSJuMVElLdCOZBkhK+4sUDLZAFMKRhBbBILEMSAQgjNEiIJHBcyUO5ll811G6UACvF1sPrUy8A4P/GyTcpi3LTh/VdhgMqlHaxWlpTp16/vzpOPQ5AkBQ6WPbnKfPFOf3M7RzDo1h2iO8vwPklW0eAXGfWoBwtRbeF9N/YrG4oBOO2YWcO15xKxZ+8F+rQDgMkG/+MlJmzGgmY5O6IgJ5pjzQvDgIEWFl5jmPCMiUFbrPss4IUwEYASADMEeDnkYcb+5dDhYaINbiaqr2uStblnFyCwyoark97QABHIQkrmCuni8G01xjUo5XMUB4HU695Ui9u4YbnCSYFpJjQaeEIqaZM9HCgERmI5AVovUDmjwBcESuhncOc1QYGmQzR8Ng1Nwua5IvlzRvIwtauSgJevSqx02cKTysfxLCVRb7GjgESPOet+M5+DlMH8T9eJK6dWH2mGmhNjxnpCETaLqsXzlENcg7nWfKo62K9Xv+RkAoBgg1iLr3MKU2nQsh+5rEALGUgCRcvDQ4D88Vc4wzq7gdJdAkh1TZ2I9wsPMWvb9r1cIVPh73ZYDEnNYpMKX47hC9Nsy6eMASrUEASEoTrpLBTy1AzMVbCxAMECogt0cDYlrkb/BM9e7dUNa0nig3paP/hudgHJVVMmqWZ57oeFgNQjfrHHgUd18AMwkODE2pQbBNGZbeOsgPjoXUAuQ0VGgdUefqihh4ZH6HtIdqEB+QCNLYToizqlkmyK9I1xE6L30IKnI1iM4E4uCnxtDVPA7/xw27HlBgCoUPRwAIGs4E9gk5gxQaxOVLBu6/VDVITTCoQfjdmtxL1JFiDcADZyEsHw3AZwunaD+RDTy9bFwLjI1AoEEK7xfvKADxtUhWabQW2YIVtZ0W4Y2yEvKhXzhrom5zDsfo9I6SjE5wkk67xXseYGaVlhaoMFLXw1uE0rAWLjWJgWEpAakzf5skoGPP86vmOERmaiYBkKUdhsumX0yUhzuPklLY1ATjgVbDNfOYMbwf7ssXswQaBJoirEFY+WlGcT9qDdMc+j867uF9VYPwdQ7VS8gUlJZmRplYHEk/s3V94Ug619etpUFurg0ItcfON/pC2yVqxaX24PUpFqrOsYvFN5/2nYBwjr1qDx8MjjhXTZgu3Rs6vz/PWV1x2co72YipxDSfqTm4Dx0h6YhzS8KUAsIRABKCJP6y+yRu6HUSh9cUxE94UOrNWB1I8rj7NPCUmoPXoxAOmleRdiMxdoNlTX+eLzEnnCZx/WZI/DXUGnSzO+1RCxD0D8PTKWhibe4yUa4/7bzAvKoJC7XHuU0dTHxOGzdxmqRALh+djAloZdGADLjxXTz/EU0s/O53Tm5Y143uXp3szgnvszFp/5IHNQMr2yBCEv5lLpBAu1BvoPd18i6C/ZbnFuk+eVgzymw+pmyZWAgpfRfoTcVjimdCSGra/94htAfUmp77vvbna2WyFpbpTng0CKwJ78lsVpvwFH/pfYEtbZrBtAgrhknCKHjfrnsDq4m/6ATbGsDp9umG/fjJyTnjuAAQW/Xw9hvbCsWWAaVHh/Ixlv1Zdmd3Tf+BvkQ4b1Zj4QdCwDx9DQvW4dwqKztfot8tRD6XYMLUVx/hNQwQ9nv2bL5JUjEu0QjLLFE40rxmGUwkuEh3buQCeDSXqud7tEg7RVa1wUxNdLwp5gRgOj7TdVztutQeMaiUfIWdzdtJwLYKzR72GdGYRQn7bybox3E6RCLW0o3FKogUfYnSlY9K3WtxHso1WJmGYm5/aouwoC+SAOHLjxKxXyqnOCBfqFkp3ObUA0ZZ/6HHTE25TeF8nXV+A9m/YbZu7+iGyApfLjtZLYz3Eq989KAtl+tNgfZw+X4m0iN+XOeEgLQrOnA4QEix2YOsjISDsg+gbO8+TW4EIKufYxChc7caJJzwkz4DgYyYKXYM7EuDJAAErTzuTrwGJ2Fc5dAm1kmY6fYSfOFhQAhGGBLeH89jcMSc2ALvwHN2NFMFhCPPScdJDM2DIXNVEi5fgYJH5QjBkXDpA5Z5z9bIuW3bnsM7B1ERDRCaWaMuOFmhMDg0BRSHA+QSrLFFMGz+iq2yQjAoNHfvWNJcr3M4QNJG36X3aJDwngiJuTWHABCDg+nvekzTQUiDo0GDBui3ZULjosNdwgYCfcIwICwrgwQgJE59Ci7wlQ4San+Dw08JiPU/mTKQ8XiA4RkgBoalITgSUTcIhwGS7A9QmpPBHBeMsCYMBobBcmfOMGmMPjFF6xLqAaHwwRAP24nTn/rG4OCqoF6HQdz37hrle8h/q/2/p/WoCgNCLeKlOXp5YVZCwhEGxCB5F4DciFbxRrSO7/qQmH1rgLCDHgUIMz7USeY1PHQENeU2wDAtkov/b4PaplwNVT4dA0cmyzC6amDYsfFj7gi0hwJCLxa8V/w9DmMedRayRaSZxwFDDHISEGiOxGnr3AtbeH3P6wYJf4qXLmbYiAPEIJlwcTMdTbZBMwLCYMCHlufJs8/AzYttazguQf6sRj4RDpvkxXksuIi6qGnusM/39z1Oexggbzx+pWoQnaMDDcJK6CDJhOmAAVQOhvGeoZWSJsM0hvbg/0MogKUDVjTU3/H/zxIwIt5ztIKh3wEQdXuHATE4/I4zPY5xrXrB48cGhXmHAWEKyxD9O2oPXjcZr5YgLKo1DA7cq2qOw2gQAqKvzfM1SP1BzttYbR6WC2d2cm4OtQiBKD+9r4xp2l5Oq9soeC4+S1vMeFTtQ60BDeKNxKJ5qMdhOCKDZv4N+26HHPXH5uWu9W5Y96xCQjhCZpaZVocCRLUJWsV3ISz8d31NYjZu2riVUp/zQNCS1wTEWqLYi26VmFPaRj0s7l7/P6kInh10TD0MHnqFv3IpO3GUS1Hp+8DTgr6JyoDp8IAg5AUeGNUg1CLUIATE11Zx6G8YGIRDAfHhiM040+5hziFyrxYghGTmlafrMVz9nGvr8uVAr780QIYVtMD3ybKgrL02HHnIHzYizCfTHgYKn7XaY4hAQt+8MkA4J8drN8lNYgMg6RigtRab26ygrJg2LdqbjbyB5lABIDw/R9PT/SVAqTVoWvF7bh8WEIICSAgFNQj3j/SdpovL8f2P4X4cf+M8eU5sSoB5FUAy/n6J6TTykCYW4/W4as2xl3NsCu+WBCRp3S/W61ifjHWO2sLgICDhuTrpWFeA1049B+9TRJ2gEAqKNvJIdQ1paJH4vlf+FfvSM/mdphX2qfU5x0v/uTBOJfG6lw+axPQYqzcQJvo9mFdhqcqHZjHB7LWDiKxlS/vFSoxtwD5MR0c9LKa+49gvQSFYhaXpg7tSieswFK9Ro1p/NagMQaWgl8wXfmegWauWgFVUAhsXBcxlhGL7XKnn1WWEojx2qEyFsEnR0fOvPYc5gyhQdf1hoNB85EufW9VTR8E5zkEX7me7CiQvDyPZCIXpn9QKx6dK+8Tmep4hnntfxypvlMzzBsj6luNlT585GLO4Rt7uBQ3iy1tY6ZHX3fZ8f3TMR8mnuzBWgrwzodbyzui01rt581LvJnjWbIwG8288Cv/H8pvhSUGNytBX8eXYcUvcc8G8pInJa8VfCqcERLdL7lZACALdrK5sovsIiei8J2OMhFBxdf36WGSB42BMG57aVmI7F7nFNeIT3LVYhq2hxfyVaSIld2n0Agdl3ctWMQwADye1Bys0X7bT/rKZMuQa5AW2eV93NB8amNXvot/xESD5FCYW5ZosV1ZNfTi8OsdJ4lWrUFecVqv2xuLcLGtOCqxeRM7gsHLF5Y7+cwNj5essfCMAhKAk+0P/ASRHAgRRpZ8trJ7UxHfSMYyBFdkgMUAs1VacJg9MH9iLCoZ9x9RD6xgl8KKoKxrnZGoZcyxatXqNTkG06Xqn1v1Cj4cWiUFcEZcS0oXowoDkjbBCnYNs6sasmjPHM9PTtCu/3maDlQSEFXjf26wsnmxvN132D5gvf0RlpyzAqoKMMjWNu39AWQBHGJB3+pTJGzj2uHoJiAzGOWsAonCwsrnBypsUlMGTqsEwWAhIWOA9DN5Lj9dvW+PAPMBzSDygoOh24U3VgFBjKCTRgCTNxUqYgKQevV3YZqT3yZjywAhZpsxTFWgDLvanYHCJUHozAZXFvhGOMCBpZVj6aTrmiwCOikos+IHUAOGSUCsxpMC+J+GgbO82FYv+ufGnJAxYxsfE6jPEpDV3gOD8bCwVCk6MomSi0a+9DOkPggPn8U5hpiVMffxrg4QpZ2XxewpV326MbLqpqk6TBNqjI/soiBLtMSFai+C4NMTbHAoQD1pENQjAoAZRMEJ9BP6mMBAS2tiMr0JH24Mf3usLz1vRDRqpm4LvuGRpEkyooJAJCCpLvB9XFKzUaIC42WVVeK5ukFqfECg5RUMyggA8A8Sihd/G+NAuaATKXlT6moAQirCY9tgJqLjGVnHRqQoHAVEBfAEc1a9B9hSUEzLu91qfDzf6zQ4UahGuVRsWAhKChA1E7NmDgzKMbZknse18l3d/LLtTBvOGeWV9j1AnmprYNEgErmAGka55Bcu8LrongCQAxAeFLuMIpkdzZL4B4fI1x6EASUI/lGAcqMqTq5bM1e0kXX7I1bcSDDHchj7I7Oa9pIXf5zA4jgiIX19RqFyx50f93OB1vigws8KAcISWgOwBIO/qaiAMIEPh07zKhsC84jpInJtA84qtLM2tDi09SRm6NNAiVhA0sZqV0cZ1neXIgGkSc+xxwpQeJtUmAMfjm4bYIuGhNWXLREByoMYBRgq8VskIYz8GHUZqE1fYdAqg0GHbxhWU6bFx8JBEaRAHSOnhcu+HAEINwrkKpj00PQIgo7wOsu63WJXDtAchQb7hnsIvrKx5i5PwxWrIHl++QLofshnyhUctc1U1JFqBCQnXGKuuOLod2/q8GnDQ7I3WIKY9DBDe386dYwJIagLCsZTw2IqBYSnNK0qDuevUzErHC3F2v811nMsVEC4qaMvTEpb6dCz49x3eJij8PuakHDh81gemdmBiOe3xYwOSzMWq/6CdYNqHkCTGXOFGGHvD0IK3AITJ25jU8t4ZY+TTxXwLEzqozw3TkGPzzfO7XM4LR+tvnUgudGZiAWtchdGDCtfOIwGglvAlFeEjqW3OkdRLbofNCq/JzBcDaTJvA47hwserpfcd9+l20CehSkcLFXPCqeoE4Hvu+BKWwFvX7lwuAWOfQ4Ub2HdRGuTLfS68fPf2Ppov2zpUR5pym96V12AO7IJZQKnqiUYkJNswOYpzF/jSzYuw/tXnnPcB17ClfvzQZLuxw6b1Tkr1khu19NKyT/dOzoECxadB88b4u9ZrhRHwKavwrNsxtrDp2zrztqgkXHr/P2M7o28YAiVqMWvkWU1AEvg2YLxXPnMeUuT1kkddiPzOdwolaxz6jXNfDqQxtjOwbFTxHffImqfydZurI3IBOFsMzlzKx6BTftJ8HIv5POufcWYrA2Mj0y1kCcGTuDaBSZ+8ShpcukIiw2+WOD9sKPwMdMLYYG9kDlZIKX9V4q9YIV7kWD6rDQhi81//cFGtWoBYYBpX9SYUb3QoxRgIFldA/0IBARiEgcJwa0ZSctsiKgkIPS10BQZLZSKzufCyLXJtkOgavPiNhcFtQqGC/kYYEIVj+maFY2cVonpfwKQfHGN9EtUm5r0ahgW4+QovQBIAworkPuG+RjgHrS/ihU0sA4Rv7E1OicXaTNXjNASEHiMCsg8dysMBQkgyMeD33Epqj2o4CMmFF2YR3HbhG/kB2wEkhIOQGCjx18KrN3Z5EPfGd4MEeXYYQAhJXYJCSFCWhEPLGrAwzwmGgUJA2E/Z9kp3WbjyVleOgKQmILGwIE4rf0UBWbrM1Z33sO4Bz0cwUgAlRc1FhC55vrABVPcyXPdxfnQE8kc9lYREAQlD4hqDHxWSJ8MaJAKPUSZbdVyI74UgGDSnPtsKnz4WhqYdLSFADIrAP4/jIjCTzBXJDKAGeWv7TLy9tasMuXmTZooCApuVUIQhYQef2sdAoQYxONotfhKFRbMkV3rPofuy2qul772A+eXVqRv9Ci9GC3A9MA6Qus93dtrOzm0QdNIJiEkBRr31/eToe7H/RSEgz2JgqyYgNEtVk6CC8ZjlWNJHG5UQIO+81o/5XOnf1/dPTj65TuigtV7P6VEahJAQEIppErbIYa17KA1CQBKoRVAOXBcgrEUMDIOkxwK43wHI3cu4ThW8UtAAhIPr7TI1DUJAMmA1pI+9XwZjWrfmBRpVNposx/T5W6B5cD14u8IS3CtgUAuBb8ZyEAhj8Kg9wpB4Y51DAvsM9fMmEsqj77VpFaXEu2CRPpiCgkyhmWVahKESOxZWP1AlzKu1Ra7PwYcMR9vSLWjag5WcA0pcqv+zvVyZJDdYtt8WulZIkDmaQQCF7xepwvRRM68UlDlwFwKSVKTv/36qZuz4R27QgqOppRnIlsSfCBWPcRbTHoGJdXz666GcCTRF6DvdrKwsMDNrqXmxDA4+q70b/InmeFMutAcXysaBASC/g4vSwNh13mzZM3COwjG7uF1QIcy0YjpujI5b/KvaI/wYazmaTNMq0CCopKpFRvuRDLhfhv2bFjkiINAgDQsr3EQxPD/zoPze32p5GSDUIJSCEkZWYO0tvOWK5UmvF00tA4RpMrxm2ZMfUvcxtQfPR6jSyhwc1CRhOLgdAAJNwntmoCkjJJjvlDg4bsKQaHh7NSSmSX4QJOGK8r43CX0CCOdwU3UlIhMb4AboA69EZ/xzuDn5QFyyhTd2OZZkoXZ1HUQAABI5SURBVHA7FtMm6f1KwwO1mQczyX8dwhosUakjy1W5suSuoZpxzbiKN1oXCjOSy/ssWT9Hz60FUO7U7qnznpf60DyccMP91my9SvfhvGy+99Dei662KCOLcR8xbF3KYFaFxWnDG/H70Xys0QgGCgVvkArLEys7Scfux0qv846T8nnZMg9LETEqdy/mK4Rle+sZ+v2UKY2ijrdzrb2/J+/ZVtswMI/mHg+1T/h4vspij5c/UcdNtLGAuRmPEBLv+FM1n2iqWMWLoJMelgQ0RCYZZS8g79dJ76vnu0U3UP7btmNQEuXB1dipIdLQ+aZwQYeqLW4ezbBbXV8xHX3NhLmI5jaZ5ca5uKLJxkcRxYxIjG8/6RNAxZcA1cW+YakJsK5WTxfzWYP0WfCswfoC+kx+pESk4Dr3e9euPQ+VYUf5XbbNExnsTcLAlA+ILnQAUlNhshAQyvNTClR4Q2EhHPUwQks4KMw8QrIT85ZZ4Xdu7iq9r0BhKQwb4cnaBI8VbEz8f/fjd2KeshtHYVqKJX34vcHBlP9zTrOeCwF7rYaeL0ljHlL1T0iiIncZYhKGg++x8zy6do/2EzQaHc9usI3XtAodpJ8WooM9VEWwvQ/vS7y7uLvCQPOTQmAIzjau6VUDMP5f9fJA3ld4nnRw3aO90UPsR0ispXSQwC1sgDCNxSvUsI+KzcnXKIQQJAYH0zTGWAGQrLE3B4Ds2zVG3b98lwfNqKYzVqpJnIdV3Zc9SEsBFgcWoGO5ERDOLK0JCBfkKCnwAkAO7h8k8x9+SI9pwTKHeWeQ1AIEHjpCUgdphMuy2vNY38pi7ZDGdypyv3fr1jKUX4frg4Z2CTZzLUNvDwPCVrkOOrymQQwSpnpDXEmb3i4KMiIMBzvhBseSB9GpQ8vCfbLKN6pwuyU6cS+/Ro3AueqACHBMnEw41ikc3KcmHNyvZHJD7eTRNrYFzBhvxXtiyvuOAsQtPflDXX9Oi9So4ISDYFB0mxBBCAqBoHCb36nUOD4Eh632Z1orKJUfaWMhx08UEMRXMY2/HPa+X4axaPxo0zN2KoL+gWmRMCDHwCzShfzgeVqzZmzwTHc/+UstU3qsDJDOhSVSdE1xsM9DG9w+mfNwDWgOg8RWVNQ3EqsWyUOkwiDMyLxU7D2LYUgOCYhBAlDshaR8LjUdLVrbT72WPWpCwvwOa9zDZbevPdxLRtS8CmuQulDDBIR9isTW/SUZwYwRrhVLONh58yVnIUZbUaEplbA/rWIYHAYGU+5DgD7ZzcrjFnIgHHkFDg63qmI1HOE1YEv5ZiEUVBgOahJmTNQUWtMgCF7Dbxwr+Fc+S++/v1WUFjDtYak972HTECDvvt6H90TNYXD8K/f2Xcdme5jnEvHhME0SdpvGYzxJATmMBvEwtmSAjL9pZlC2ZmaZBqGJ1XzynShHpz2YF1ytUdc3mIGIXzhjagJiWoSL7xEQmlrsj+QBKA/HKCR0FtQYp6HmiBI0imFIEic9rsGoFpSqg6pYdASZJV63boWhTDuqhqkRDvhz3PAbvrQMDNv0rHjsGPF1wboKCPonnCfNim5zprngHEdaOZhklYT/szIzbQ4Vm+SbVFz31fZhSo9USQlePzYR6/cCOC4iEGiOO+y9H1xHCeHa/e7VfaxTbutbecdlwGRb46I4Mf85iF9qnf84ns06wEeVGaHMC28updvXYrPC9/99tv3Rcg4IMs/5Me3t/vv3/F2r8zVCDZrNy49BmA4uqZXLOuzM25oVMn0m3v408RlMg3bLqbLf8OW+kTL6Ht968DvY6vHChK41z3DVRr/x24HBXdQV9iVNbIq27o8JXY9gUWuLgGa67+0ZrnOPOqNvnEI/Jxx6FHV/GFtRWBiwalOG8Vw61kMriB17Pzg17iw/uqD3tKnfJ6tfij3jnM8iV2/4ZxiQWADBzGM0LNWwZqTv+QjDwW0uWVoLjlErFA7CQzgob2ye7Wecb3oAkLkze+FFnRsCODTTcM4lARycQon5Hj4cfMEKC1Ndur4nI2H8AwEciP93gNC0OqllkZ8R/woclpd8lddSun+LizI0NIQV3uaMHAkU7sNjeLydDOmPcU+h09XatL5lNx2ADQHCSkPNgSOEb7plaksgHQ4Qq/xbN8K89AGhtcDyN/csU2/kChl/LcfIHCBMzatl/UoDpAH6qxq8iPGh3dt4DL1gFAwnbMccHtQZSgadOSFIogCBdjFAmFrHXc1HP9LCNAnThKLF4vWb/6BHSNqP6lUr1/BFuNV6iZkTP+WJbwwOphYqzhl57ACTRoY7K5X43zQIM2fZqqX6QHwoQjJ16jnqE6fmsKVMuezPzu1XYL882OxcNNkBcut8jFnAx87M5zqwTKlJnFnlMougcGl83YerVCCjFI7TOjlo2THDEqoEQwXbGgV7etf5oYf/Pp2y0GGH3SQsJks7nF3/TYOFMDz7ZDcVLh3EBeiwL8Hg/vb5d8Nh17H0f8JahBAwD02DYCex/siRAGlQ/BhAr361w/53BiggHLuwgT510yKieyc0RzUkeF3G/U7bEBJb4IMp1zLgXJdcLDRnkHyx11kihERfCDvjVTlzHho+gsIO/+FMLmiRRHi3YvwoZj6fgm99Et+7pfVj0MIdConnNbFMYloLDoZ+R8EBU4sZRqH20M46MlRVsK+yCEbR0sd0eRqXCQ4OmkocMDI4uE3t4qAwONiywFXMRaYBBwf7bJFkwnHvY/fgdwfHmqfQwYcKJhz2kpUG41ZLrGkO81qE4KA2Qeh12LTic/+7P/BdeF0gl0OWQxb7wpejZkL+Ux/TInm4gaDPSAhUC/uTyqxCUascDhCaWSwHLobw1vMdtIxoZs3wPU82jqH7YD5PtBYpkE92jQ1MZ1u7wDQJj0lpf5kMyEnxIeHqJA4SmlsMmGSdoyY5DhJzOED8jju9c/q8eGY+G7VGWIuoCc734RxGg3Tz/GAwPRB0cQV2D5NwvDY6qqsnTx69JHDZcqX38Grvb2zoCo8DXbh+Rd44UrIK6dZbpy9HYZqCsGaqVgeQ28/2L76prLqzDfuVD0956fkbg/137hgrHfrlS30Ns8bvGN2nx8yCGBMwUm9zy4M+B8PBs7u/gswp8GtkuEHwv/pREmqAsHzXSekx+X9ba9S8p9/oOgQzHnGVxW9NEy5b8S12DEwtWgo1J6AlzIJWhmjlR6M2flp1ee7cTueKq7ypGBSkcL9ITomsf4oxbNX7MjiR+6ZgjIzuX6YUOnsalGPMq3m+5OV6/msT8GoGvKiTx/O9NLQqtJ4AkJqxXgo8ofeFjTpH2PlcJrFNshHXdT0ijaGFMAfKwwKKNTOI/3eD6EEGB6edelyrKnQygyPsuuXNXfXwCtmNeCR7aEJSWQFNgIDGRLwYnm8OIhwlIP6d7VO1sn+xj+5Ol0ms9FPntwvgoM3KQLWm8zbV2n/8tRMVEPWUHQEOtgwBILnn7fXnUuBxorQl//93fmI44So314t0w4Qrim3jorH/zgt/z3N/5I29PWhYrFW1Ftf6I+EFMDhGQkBMmhAWLFhNMKxcS7G6fhgSTrumcI2C97ZXN6Tc/1CQmDc0pRwhRy06al3cuj7ccXcm+drN811fBHWRo/QcpORIPcGgyaiAAA5btIPTrmsu3BHXBvNLWvdk7Jv1T4MsnIMtnWnFhQq09WXvHi4x/R4TVjws7uZhtJXhHTbgxwcfAnOKD2Z9B4KxekVLSS96WBr2XYoxDbYEmxSOJQ+OwYqChCIvSJkxa54ZhxXFnZZhC6MdOpyb2oRvJgrvz3056YoZlzRrtWoPnRfC+x9aVquAFRDC4XmTIPwcjY/b7fn/r790LX9ErWHaVyFBpTJI8LvE1G8iEdjypkkMjkCL0IQKaRGr9DSBqEEIB8uY069TMzN11RuDiSlXjszGQDLrlqbY1yChJuE0Xt7H2keyfQgRjgItwvr33s4JznWMY9k/oZi5yCnBfA4FhKD4sCSM/pXEnt5NYuo2MEVgQau1Sv9Z75RWuliBAcLUa48QEJpYmItMMTiY0lPxhR/uzRtch9cYEAr2DZqNWxVoDWqPnW8P14cgIAbJ7nd8rcEKD+0yuqxvAMfCBzhxhi1RNUyf7CpUkGhaGSApcDUzw3TGGq6jheqbCAp4NBy1HvqnL6JygJD8IwoSv08ShiQOI9Q1ATFQ0jk5C1pkzVNOi3yG/gK1COEgJKZBCEmDoju17LioRzUkefLxH8cFFd3gsFThgomP+9TXJBgclu7fPVke2nC7AkbIzLQK3NcYANWFBKFVtA+96G1JmLjS1SH3WoefR+VI6B/a5BW8sK4VxPWCptz/LCfcZF9RLRws3PY0OtN4eUxY3lzXcz2PbTl8rhTiFWw9x9+p2/TamHYJp/TocH2pJniBDR/axJuyXW64//7qwbfQdR68rYvUG36dNJr3osrPLgWMuCZbtUS8U5Eeq8Ck4qy6Jk34+0AIPz9pDpcPh/trfTJGuYpGvWL+SGQuRtkpiIqNu/B6V5HwexzmV8Qj+jYepkwgiAq2Cjx+mgsrYcXf8UK+pPRwk+RoTZjQumiC+sLrWZ36dNcQjUJg+uvlXb5tdOVyt0AFUm57fL0f+pNc1QVGgRRfkBFVD8N1culCxAXaVGRLseCFPl/DlrCKsM056tURwBa8WKtPaJljmUc1oyciHBcscoAwDd8At//yZr/3uW8Eo5FNUCkNjkm4oT2b2x0WDjs/ATFh5kbBwVFmH5AdG8+FlrhB0ha9IQ2xUgchObari6VJQMSmunPxZqwgQwiHm7/NZ6r5fPzup0/tHLB8CiDRSNgwJINnar2IbT8Y5goXwXDh8nEF83Reia08T82+5qnqPubiOelYvqk0MLkNElb0JmhMcSsOEj9Mx8J1blq5UsHQZY4MEEICUUjocbJjQ42pyGD56COY1tMe+UJl5HX7PYoB4tdvHgthp9zgOGJDahmE3e/vhoPWmgYZfNNK2bPHAULaKaQX+6gci5gWCl+tS+1BOChhvz99/9QaOIYjxhSOAZhsq4v3Be7fMXh7VACf/9BTL2sD4lcqHASk/sQHJIYqMeGYQHvUMUBGIc7HaQ+c/ifNwUz4AR9WGMzhr3Th4j4khCLWb5jiRiwKAImnQwf7p8H8YUNHUPhO+v3vOPOJKQMQaX41gxnWENNsCUkTVnRfePxdS9p9S+2x/vG8f06dkP3NhRMm/P2kU075KBVTcQMNgv1Vk/A4AJaKcHoey/podZPaQ+tnxhlv4jeGFDkZPLHYC0s1GNjlh30mpbfusMhAycnWCq43hNNtvmzkKczIwSFhZ3hSvx4NFlGw/T+Q5ZArIXmQ8KAY/o368LeelBvn5E55dU3v5QSjV/fmer0mqPRxDdIl8fTOEmlyun4Xd9YApz04IGgmVsuzf9IeUdn6g/+ZwhD4+BlYRCMESPxMDLideJouHaTmlWmR0W6MwSBhh5pQhCHJ75oiWTkdFRBCYnBo6oJHD+Juw7IH/5toA+zRLKOgIT4WEdkm2M/qpaXmmPnBGXC0B6Zix0sg7KPc2rSpN+78873TjuLgf3WUOrGv1zjpHO+U9HPPzTyVKa7ZGcJ7eQgC71QjeK8WO/81fdi0KV1GscPJTy170n39098j5ADdz+aCfto7G2NgNG/QWkeu2YTXl209GD/1ya+xD2KcrkPDhPWMfXEmDMzbdpOcYJ/FC86Ew8W9is1Wf2lx6nEyZAAsEK5DRvErdyO3ZtVHWVne/c2aeYO8xm1R5t3ivZ+dneKd0AYLa3oXQVj270OC47jdqBFfkxH37M9+FkcT8XAfmlCsEyaH2+9H+94uFE55E2E4+D/Nt2oT7vCXt/OEjz/c3in4gV4H+q3Zb6LQnqQYILz2T5/vnwOWb27uCEwcBQRwGCRxF1z/DU6rkHBwNoIV272zr9iBCA1UXCdntKi2OBjUuWAmXq8NOHhctCSizBqtVSiO7l7rYDcEm2ZjuoJJq4yjO/S/Yy9WcGuFfsgd/avH/5Br/nRMdA6wseKHYTHQ1NOF2iMssc0716jo1XB4XuO9OC7c17S+ZyhttBYapBv2O8wH2uOnz0858H8gBxSS2NwB38YNvPobag+KrWEck1zfX+w79WE8C21/BvpFBfv9H3jGn27xpxz4F3KgaZsWOJrzJe6EcLWVZZCFkDGQMyF1ITU/tASOJGZ+m0lX8/if/v8pB/4/lQOs6DSLaF4fCQz77b/64f8f+92j6R/avUMAAAAASUVORK5CYII=
                """
    
}
