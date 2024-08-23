//
//  AtomicScoreView.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/27/21.
//

import UIKit
import APNUtil

class AtomicScoreView: UIView {
    
    private static let nib = UINib(nibName: "AtomicScoreView",
                                   bundle: Bundle.main)
    
    /// Factory method for instantiating AtomicScoreViews via nib loading.
    static func new(delegate: AtomicScoreViewDelegate?,
                    withScore score: Score,
                    andData data: [String],
                    textColor: UIColor = Configs.UI.Display.defaultAtomicScoreViewTextColor) -> AtomicScoreView {
        
        let scoreView = nib.instantiate(withOwner: self,
                                        options: nil).first as! AtomicScoreView
        scoreView.delegate = delegate
        scoreView.load(score: score, data: data, textColor: textColor)
        
        return scoreView
        
    }
    
    @IBOutlet var dateView: UILabel!
    @IBOutlet weak var averageGameCountLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet weak var optimalityLabel: UILabel!
    @IBOutlet weak var optimalScoreLabel: UILabel!
    @IBOutlet weak var todayView: UILabel!
    @IBOutlet var fruitView: UIImageView!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var scoreStatsLabel: UILabel!
    @IBOutlet weak var scoresStatsRoundView: RoundView!
    
    private var delegate: AtomicScoreViewDelegate?
    private var score: Score!
            
    private var data = [String]()
  
    private func load(score: Score, data: [String], textColor: UIColor) {
        
        self.data   = data
        self.score  = score
        
        // Date
        dateView.text       = score.date.simple
        todayView.isHidden  = !score.date.isToday
        
        let imageName       = score.date.isToday ? "PolkaDotsBlackMid" : "PolkaDotsWhiteDark"
        borderView.backgroundColor = UIColor(patternImage: UIImage(named: imageName)!)
        
        // Average Game Count
        averageGameCountLabel.alpha                 = score.isAveraged ? 1 : 0
        averageGameCountLabel.text                  = "/\(score.averagedGameCount.description)"
        averageGameCountLabel.textColor             = .white
        averageGameCountLabel.clipsToBounds         = true
        averageGameCountLabel.layer.cornerRadius    = averageGameCountLabel.frame.height / 3.0
        
        // Score
        scoreLabel.text                 = score.score.delimited
        scoreLabel.textColor            = textColor
        
        // Optimality
        optimalityLabel.text            = "\(score.optimality.roundTo(1))%"
        optimalScoreLabel.text          = score.level.optimalScoreCummulative.delimited.description
        
        // Fruit Icon
        fruitView.image                 = score.level.icon
        
        // Border
        layer.cornerRadius              = frame.height / 5.0
        borderView.layer.cornerRadius   = frame.height / 5.0
        borderView.layer.borderWidth    = frame.height / 7.5
        
        scoreStatsLabel.rotate(angle: -22.5)
        
        // Shadows
        addShadows()
        
        // Interaction
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleTap))
        
        self.addGestureRecognizer(tap)
        
        // Invalid?
        if !score.isValid {
        
            backgroundColor         = .black.pointNineAlpha
            scoreLabel.textColor    = .white.pointEightAlpha
            scoreLabel.text         = "NA"
            dateView.text           = ""
            optimalityLabel.text    = ""
        }
        
        updateDisplay()
        
    }
    
    @objc func handleTap() {
        
        if score.isAveraged {
            
            delegate?.didTapAverage(score: score)
            
        } else {
            
            delegate?.didTapSingle(score: score)
            
        }
        
    }
    
    private func addShadows() {
        
        Utils.UI.addShadows(to: [scoresStatsRoundView!, fruitView!])
        
    }
    
    func updateDisplay(useData i: Int = 0) {
        
        let colorFG = i % 2 != 0 ? score.level.colorLight : score.level.colorDark
        let colorBG = i % 2 != 0 ? score.level.colorDark : score.level.colorLight
        
        dateView.textColor  = colorFG
        todayView.textColor = colorFG
        
        let data = i < data.count ? data[i] : ""
        
        scoresStatsRoundView.isHidden           = data == ""
        scoreStatsLabel.text                    = data
        scoreStatsLabel.textColor               = colorFG
        scoresStatsRoundView.backgroundColor    = colorBG
        
        averageGameCountLabel.textColor         = colorFG
        averageGameCountLabel.backgroundColor   = colorBG
        
        borderView.layer.borderColor            = colorBG.cgColor
        
        rotateRandom(minRange: -1.0...(-0.5), maxRange: 0.5...1.0)
        
    }
    
}
	
protocol AtomicScoreViewDelegate {
    
    func didTapSingle(score: Score)
    func didTapAverage(score: Score)
    
}
