//
//  ScoreData.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

struct ScoreManager : Codable {

    private var gamesCount = 0
    private var highScore: Score?
    
    var data: [ String : [Score] ]
    
    init() { data = [String : [Score]]() }
    
    // Adds or updates score in the data hash
    mutating func set(_ score: Score) {
        
        guard var currData = data[score.date.simple]
        else {
            
            self.data[score.date.simple] = [score]
            
            tallyStats()
            
            return /*EXIT*/
            
        }
        
        for i in 0..<currData.count {
            
            if currData[i].score == score.score {
                
                currData[i] = score
                
                self.data[score.date.simple] = currData
            
                tallyStats()
                
                return /*EXIT*/
                
            }
            
        }
        
        currData.append(score)
        
        self.data[score.date.simple] = currData
        
        tallyStats()
        
    }
    
    mutating func remove(_ score: Score) {
        
        guard var data = data[score.date.simple]
        else { return /*EXIT*/ }
        
        for i in 0..<data.count {
            
            if data[i].score == score.score {
                
                data.remove(at: i)
                self.data[score.date.simple] = data
                
                return /*EXIT*/
                
            }
            
        }
        
        tallyStats()
        
    }
    
    // Converts data to [["Date", "Score", "Level"]]
    func getScoreArray() -> (score: [[String]], headers: [String]) {
        
        var scoreArray = [[String]]()
        
        for dayScores in data.values {
            
            for score in dayScores {
                
                scoreArray.append([score.date.simple,
                                   score.score.description,
                                   score.level.description])
                
            }
            
        }
        
        scoreArray.sort{ $0.first!.simpleDate > $1.first!.simpleDate }
        
        return (scoreArray, ["Date", "Score", "Level"])
        
    }
    
    mutating func tallyStats() {

        gamesCount = 0
        
        var highScore: Score?
        var high = 0
        
        for dayScores in data.values {
                        
            for score in dayScores {
            
                gamesCount += 1
                
                if score.score > high {
                    
                    high = score.score
                    highScore = score
                    
                }
                
            }
            
        }
        
        self.highScore = highScore
            
    }
    
    mutating func getMoneySpent() -> String {
        
        let money       = getGamesCount() * 25
        var moneyText   = "$\(money)"
        
        moneyText.insert(".", at: moneyText.index(moneyText.endIndex, offsetBy: -2))
        
        return moneyText
        
    }
    
    mutating func getGamesCount() -> Int {
        
        if gamesCount == 0 { tallyStats() }
        
        return gamesCount
        
    }
    
    mutating func getHighscore() -> Score? {

        if highScore == nil { tallyStats() }
        
        return highScore
    
    }
    
    
    func getScores(forDateString date: String) -> [Score] {
        
        data[date] ?? [Score]()
        
    }
    
    static private func getLevel(_ from: Substring) -> Int {
        
        for i in 0..<Score.levels.count {
            
            if from == Score.levels[i] { return i /*EXIT*/ }
            
        }
        
        return -1
        
    }
    
    func getScoreReport(forDateString date: String = Date().simple) -> String {
        
        let rawData = getScores(forDateString: date)
        
        var data = [[String]]()
        
        for datum in rawData {
            
            data.append([datum.date.simple, datum.displayScore, datum.levelString])
            
        }
        
        var report = ""
        let headers = ["Date", "Score", "Level"]
        if data.count > 0 {
            
            report = Report.columnateAutoWidth(data, headers: headers)
            
        }
        
        return report
        
    }
        
}

extension ScoreManager: CustomStringConvertible {
    
    var description: String {
        var i = 0
        var descr = ""
        
        for scores in data.values {
            
            descr += "\(i) : \(scores)\n"
            
            i += 1
            
        }
        
        return descr
        
    }
    
}

extension ScoreManager {
    
    static func importData() -> ScoreManager {
        
//        let rawDataString = """
//        9/22/21,60000,),70000,)
//        9/21/21,62550,),73810,)2
//        9/20/21,44190,),32600,&
//        9/18/21,37080,#
//        9/17/21,51460,¿,45520,#,68730,¿
//        9/16/21,39490,&,54050,),61880,),31200,&
//        9/15/21,64440,),59810,),28910,@,63190,),65200,)
//        9/14/21,43200,#,41020,&,24390,@
//        9/13/21,78190,)2,26210,@
//        9/10/21,75250,),38260,#
//        9/8/21,41760,#,55320,),44430,#
//        9/7/21,29410,@,54650,),37910,#,56480,)
//        9/5/21,38170,#,2030,*,37960,&,15970,&,36620,#
//        9/1/21,56740,¿,35060,#
//        8/30/21,44190,#,63670,)
//        8/27/21,28240,@,29980,@
//        8/26/21,12750,$,31590,@,61790,)
//        8/25/21,44250,¿
//        8/23/21,33570,&,30290,&
//        8/22/21,48060,#,32800,&,39380,#,48690,¿
//        8/20/21,47700,¿,48480,¿,34100,#,63620,)
//        8/19/21,53430,¿
//        8/18/21,76840,),19960,$
//        8/17/21,30990,&,54830,#,38600,#
//        8/16/21,42170,&,27500,@,67840,),42240,¿,71000,),63790,),50180,#
//        8/15/21,29930,&,54450,¿
//        7/11/21,45660,¿
//        7/10/21,51350,#
//        5/18/21,58070,)
//        5/2/21,41770,@
//        3/2/21,72150,)2
//        2/26/21,57030,)
//        2/23/21,42720,#,33860,&,54470,¿
//        2/23/21,33350,&,47070,¿,40150,#,42880,#,31070,&,59300,)
//        2/22/21,44930,#,24800,$,19460,@,53680,¿
//        2/13/21,72260,)2
//        2/6/21,33940,&
//        1/19/21,51870,¿
//        1/8/21,50150,¿
//        12/18/20,67180,),38390,&,34720,@
//        12/14/20,29230,@,29860,@
//        12/11/20,43550,#,49900,¿,21120,@
//        12/10/20,34900,&,53090,)
//        12/8/20,33700,&,46700,#,19910,@,68170,)
//        12/3/20,29230,@
//        11/30/20,36410,&,45389,#,36190,&
//        11/29/20,53950,),51240,¿
//        11/26/20,37900,&,44330,#
//        11/25/20,39840,#,62770,),47470,#,42260,#
//        11/24/20,62890,),51790,¿,33290,&,59720,)
//        11/23/20,53280,),41110,¿,48460,),54000,¿,39290,#
//        11/21/20,32110,&,71860,)
//        11/20/20,27840,@,42940,#,74880,),31980,&
//        11/18/20,38760,#,35340,#,18040,*
//        11/17/20,36160,#,42370,#,21270,@
//        11/13/20,36700,&,35470,#,53800,¿
//        11/12/20,47680,#,67930,),42620,¿
//        11/11/20,33930,@,60100,),57020,¿
//        11/10/20,45600,#,31700,@,20930,$
//        11/9/20,35810,#,36770,&,40870,¿
//        11/8/20,28980,&,25790,@,39790,#
//        11/6/20,41380,#,1860,*,39350,#
//        11/5/20,63730,)2,23590,@
//        11/4/20,1800,*,41480,#,29300,&
//        11/2/20,36000,&,36000,@,35350,#,57750,),41030,¿
//        10/30/20,45740,#,56960,),17430,$
//        10/29/20,33870,#,62710,),51420,¿
//        10/28/20,45120,#,720,*,61000,)
//        10/27/20,39440,#,78530,)
//        10/26/20,49840,¿,33020,&,32560,#
//        10/23/20,55520,),31400,#,49910,¿,43950,)
//        10/21/20,63640,),41560,#,29670,#,37360,&
//        10/20/20,36260,#,52620,),38750,#,31730,&
//        10/16/20,47500,¿,28290,#,31440,#
//        10/15/20,38030,#,31870,#,27260,#,33070,#,27280,&
//        10/14/20,48800,¿,41630,#,58270,),34120,&
//        10/13/20,44190,¿,29150,&,29660,#,41190,)
//        10/12/20,33540,#,49449,),52480,)
//        10/11/20,35400,#,59350,),9700,$
//        10/8/20,72690,)2,36240,#,32330,#,43650,)
//        10/7/20,63520,),62000,),45170,¿
//        10/2/20,57710,),31470,#,70180,)3
//        10/1/20,62270,),33640,#,28530,&
//        9/30/20,55990,),69160,)2,53340,)
//        9/29/20,44820,#,35080,#,31170,&,23920,&
//        9/28/20,64820,),35940,#,52720,),54740,)
//        9/25/20,34090,&,55250,),46090,)
//        9/24/20,50910,¿,35210,#,33640,#,30010,#
//        9/23/20,34970,#,60689,),65169,)
//        9/22/20,32720,#,60010,)2,41230,¿
//        9/21/20,37170,#,16650,@,36620,#,62550,)2
//        9/20/20,35000,&,36640,#,38910,#,26400,&
//        9/18/20,35630,&,41810,#,37750,#,30050,#
//        9/17/20,28910,@,36360,&,32120,&,31320,#
//        9/16/20,21650,$,46100,¿,48970,¿
//        9/15/20,38430,#,8190,*,57770,)
//        9/14/20,62840,)2,9900,),17580,@,70700,)2
//        9/13/20,31830,&,37340,&,40810,¿
//        9/11/20,34810,&,61600,),58970,)2
//        9/10/20,45270,#,58050,),37660,#
//        9/9/20,28660,&,71120,)3
//        9/8/20,27660,&,47840,#,58240,),38190,#
//        9/7/20,43620,#,55650,),40780,¿
//        9/6/20,39600,&,47330,¿,32810,#,34560,#
//        9/4/20,36040,#,39870,#,34440,#
//        """
        
        
        let rawData = HistoricScores.data.split(separator: "\n")
        
        var sd = ScoreManager()
        
//        for data in rawData {
//
//            let rowData = data.split(separator: ",")
//
//            let date = String(rowData[0]).simpleDate
//
//            var scoreData = [Score]()
//
//            for i in stride(from: 1,
//                            through: rowData.lastUsableIndex - 1,
//                            by: 2) {
//
//                let score = Int(rowData[i])!
//                let level = getLevel(rowData[i+1])
//
//                scoreData.append(Score(date: date, score: score, level: level))
//
//            }
//
//            sd.data[date.simple] = scoreData
//
//        }
        
        for data in rawData {
            
            let rowData = data.split(separator: ",")
            
            let dateString = String(rowData[0])
                                        
            let scoreVal = Int(rowData[1])!
            let level = Int(rowData[2]) ?? -1

            let score = Score(date: dateString.simpleDate, score: scoreVal, level: level)
        
            
            if sd.data[dateString] == nil {
                
                sd.data[dateString] = [score]
                
            } else {
                
                sd.data[dateString]!.append(score)
                
            }
                        
        }
        
        return sd
        
    }
    
}
