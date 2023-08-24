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
    @IBOutlet var scoreView: UILabel!
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
        
        // date
        dateView.text       = score.date.simple
        dateView.textColor  = textColor
        todayView.isHidden  = !score.date.isToday 
        
        // average game count
        averageGameCountLabel.alpha                 = score.isAveraged ? 1 : 0
        averageGameCountLabel.text                  = "/\(score.averagedGameCount.description)"
        averageGameCountLabel.textColor             = .white
        averageGameCountLabel.clipsToBounds         = true
        averageGameCountLabel.layer.cornerRadius    = averageGameCountLabel.frame.height / 3.0
        
        // score
        scoreView.text      = score.score.delimited
        scoreView.textColor = textColor
        
        // fruit image
        fruitView.image     = score.levelIcon
        
        // border
        layer.cornerRadius              = frame.height / 5.0
        borderView.layer.cornerRadius   = frame.height / 5.0
        borderView.layer.borderWidth    = frame.height / 8.0
        
        scoreStatsLabel.rotate(angle: -22.5)
        
        addShadows()
        
        // Interaction
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleTap))
        
        self.addGestureRecognizer(tap)
        
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
        
        let colorFG = i % 2 != 0 ? score.colorLight : score.colorDark
        let colorBG = i % 2 != 0 ? score.colorDark : score.colorLight
        
        todayView.textColor = colorFG
        
        scoresStatsRoundView.isHidden           = data[i] == ""
        scoreStatsLabel.text                    = data[i]
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
