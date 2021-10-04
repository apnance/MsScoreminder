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
                    andRank rank: Int) -> AtomicScoreView {
        
        let scoreView = nib.instantiate(withOwner: self,
                                        options: nil).first as! AtomicScoreView
        scoreView.delegate = delegate
        scoreView.load(score: score, rank: rank)
        
        return scoreView
        
    }
    
    @IBOutlet var scoreView: UILabel!
    @IBOutlet var dateView: UILabel!
    @IBOutlet var fruitView: UIImageView!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var gameRank: UILabel!
    @IBOutlet weak var gameRankBG: RoundView!
    
    private var delegate: AtomicScoreViewDelegate?
    private var score: Score!
        
    private func load(score: Score, rank: Int) {
    
        self.score = score
        scoreView.text  = score.score.delimited
        dateView.text   = score.date.simple
        fruitView.image = score.levelIcon
        
        layer.cornerRadius              = frame.height / 5.0
        clipsToBounds                   = true
        borderView.layer.cornerRadius   = frame.height / 5.0
        borderView.layer.borderWidth    = frame.height / 10.0
        borderView.layer.borderColor    = score.levelForeColor.cgColor
    
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleTap))
        
        rotateRandom(minRange: -1.0...(-0.5), maxRange: 0.5...1.0)
        
        gameRank.rotate(angle: -22.5)
        gameRank.text = rank.description
        gameRank.textColor = score.levelBackColor
        gameRankBG.backgroundColor = score.levelForeColor
        
        addShadows()
        
        self.addGestureRecognizer(tap)
        
    }
    
    @objc func handleTap() { delegate?.didTap(score: score) }
    
    private func addShadows() {
        
        let views = [gameRankBG!]
        
        for view in views {
            
            view.layer.shadowColor   = UIColor.black.cgColor
            view.layer.shadowOffset  = CGSize(width: 5, height: 2)
            view.layer.shadowOpacity = Float(0.3)
            
        }
        
    }
    
}

protocol AtomicScoreViewDelegate {
    
    func didTap(score: Score)
    
}
