//
//  AtomicScoreView.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/27/21.
//

import APNUtils

class AtomicScoreView: UIView {
    
    private static let nib = UINib(nibName: "AtomicScoreView",
                                   bundle: Bundle.main)
    
    /// Factory method for instantiating AtomicScoreViews via nib loading.
    static func new(delegate: AtomicScoreViewDelegate?,
                    withScore score: Score,
                    andData data: [String]) -> AtomicScoreView {
        
        let scoreView = nib.instantiate(withOwner: self,
                                        options: nil).first as! AtomicScoreView
        scoreView.delegate = delegate
        scoreView.load(score: score, data: data)
        
        return scoreView
        
    }
    
    @IBOutlet var dateView: UILabel!
    @IBOutlet weak var averageGameCountLabel: UILabel!
    @IBOutlet var scoreView: UILabel!
    @IBOutlet var fruitView: UIImageView!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var scoreStatsLabel: UILabel!
    @IBOutlet weak var scoresStatsRoundView: RoundView!
    
    private var delegate: AtomicScoreViewDelegate?
    private var score: Score!
            
    private var data = [String]()
  
    private func load(score: Score, data: [String]) {
        
        self.data   = data
        self.score  = score
        
        // date
        dateView.text       = score.date.simple
        dateView.textColor  = score.date.isToday ? .white : UIColor(named:"Banana")
        
        // average game count
        averageGameCountLabel.alpha                 = score.scoreType == .average ? 1 : 0
        averageGameCountLabel.text                  = "/\(score.averagedGameCount.description)"
        averageGameCountLabel.textColor             = .white
        averageGameCountLabel.clipsToBounds         = true
        averageGameCountLabel.layer.cornerRadius    = averageGameCountLabel.frame.height / 3.0
        
        // score
        scoreView.text      = score.score.delimited
        scoreView.textColor = score.date.isToday ? .white : UIColor(named:"Banana")
        
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
        
        if score.scoreType.isDeletable { delegate?.didTap(score: score) }
        
    }
    
    private func addShadows() {
        
        Utils.UI.addShadows(to: [scoresStatsRoundView!, fruitView!])
        
    }
    
    func updateDisplay(useData i: Int = 0) {
        
        let colorFG = i % 2 != 0 ? score.colorLight : score.colorDark
        let colorBG = i % 2 != 0 ? score.colorDark : score.colorLight
        
        scoreStatsLabel.text = data[i]
        scoreStatsLabel.textColor               = colorFG
        scoresStatsRoundView.backgroundColor    = colorBG
        
        averageGameCountLabel.textColor         = colorFG
        averageGameCountLabel.backgroundColor   = colorBG
        
        borderView.layer.borderColor            = colorBG.cgColor
        
        rotateRandom(minRange: -1.0...(-0.5), maxRange: 0.5...1.0)
        
    }
    
}
	
protocol AtomicScoreViewDelegate {
    
    func didTap(score: Score)
    
}
