//
//  AtomicScoreView.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/27/21.
//

import APNUtils

class AtomicScoreView: UIView {
    
    @IBOutlet var scoreView: UILabel!
    @IBOutlet var dateView: UILabel!
    @IBOutlet var fruitView: UIImageView!
    @IBOutlet weak var borderView: UIView!
    
    var delegate: AtomicScoreViewDelegate?
    var score: Score!
    
    private var nibName: String { "AtomicScoreView" }
    
    func load(score: Score) {
    
        self.score = score
        
        scoreView.text = score.score.delimited
        dateView.text = score.date.simple
        
        fruitView.image = score.levelIconImage
        
        layer.cornerRadius = frame.height / 5.0
        clipsToBounds = true
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
