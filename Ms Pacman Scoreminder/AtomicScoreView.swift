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
        
    @IBOutlet var scoreView: UILabel!
    @IBOutlet var dateView: UILabel!
    @IBOutlet var fruitView: UIImageView!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var scoreStatsLabel: UILabel!
    @IBOutlet weak var scoresStatsRoundView: RoundView!
    
    private var delegate: AtomicScoreViewDelegate?
    private var score: Score!
            
    private var data = [String]()
  
    private func load(score: Score, data: [String]) {
        
        self.data = data
        
        self.score = score
        scoreView.text  = score.score.delimited
        dateView.text   = score.date.simple
        fruitView.image = score.levelIcon
        
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
    
    @objc func handleTap() { delegate?.didTap(score: score) }
    
    private func addShadows() {
        
        Utils.UI.addShadows(to: [scoresStatsRoundView!, fruitView!])
        
    }
    
    func updateDisplay(useData i: Int = 0) {
        
        scoreStatsLabel.text = data[i]
        
        scoreStatsLabel.textColor               = i % 2 != 0 ? score.colorLight : score.colorDark
        scoresStatsRoundView.backgroundColor    = i % 2 != 0 ? score.colorDark : score.colorLight
        
        borderView.layer.borderColor            = scoresStatsRoundView.backgroundColor?.cgColor
        
        rotateRandom(minRange: -1.0...(-0.5), maxRange: 0.5...1.0)
        
    }
    
}
	
protocol AtomicScoreViewDelegate {
    
    func didTap(score: Score)
    
}
