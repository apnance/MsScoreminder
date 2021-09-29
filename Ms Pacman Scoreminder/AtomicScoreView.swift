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
                    withScore score: Score) -> AtomicScoreView {
        
        let scoreView = nib.instantiate(withOwner: self,
                                        options: nil).first as! AtomicScoreView
        scoreView.delegate = delegate
        scoreView.load(score: score)
        
        return scoreView
        
    }
    
    @IBOutlet var scoreView: UILabel!
    @IBOutlet var dateView: UILabel!
    @IBOutlet var fruitView: UIImageView!
    @IBOutlet weak var borderView: UIView!
    
    private var delegate: AtomicScoreViewDelegate?
    private var score: Score!
        
    private func load(score: Score) {
    
        self.score = score
        scoreView.text  = score.score.delimited
        dateView.text   = score.date.simple
        fruitView.image = score.levelIcon
        
        layer.cornerRadius              = frame.height / 5.0
        clipsToBounds                   = true
        borderView.layer.cornerRadius   = frame.height / 5.0
        borderView.layer.borderWidth    = frame.height / 10.0
        borderView.layer.borderColor    = score.levelColor.cgColor
    
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        
        self.addGestureRecognizer(tap)
        
    }
    
    @objc func handleTap(sender: AtomicScoreView) {
        
        delegate?.didTap(score: score)
        
    }
}

protocol AtomicScoreViewDelegate {
    
    func didTap(score: Score)
    
}
