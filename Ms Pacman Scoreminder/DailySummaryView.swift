//
//  DailySummaryView.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/29/21.
//

import APNUtils


class DailySummaryView: RoundView {
    
    // MARK: - Outlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var stat1Label: UILabel!
    @IBOutlet weak var stat2Label: UILabel!
    @IBOutlet weak var stat3Label: UILabel!
    
    @IBOutlet weak var averageLevelContainerView: UIView!
    @IBOutlet weak var averageLevelBGView: RoundView!
    @IBOutlet weak var averageLevelIconImageView: UIImageView!
    @IBOutlet weak var averageLevelLabel: UILabel!
    
    
    // MARK: - Overrides
    override func awakeAfter(using coder: NSCoder) -> Any? {
        
        if subviews.count == 0 {
            
            let nib = UINib(nibName: "DailySummaryView",
                                           bundle: Bundle.main)
            
            let view = nib.instantiate(withOwner: nil,
                                            options: nil).first as! DailySummaryView
            
            view.frame = self.frame
            view.autoresizingMask = self.autoresizingMask
            view.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints
            
            view.rotate(angle: 35)
            
            view.alpha = 0
            
            return view
            
        }
     
        return self
        
    }
    
    
    // MARK: - Custom Methods
    func load(_ stats: DailyStats?) {
        
        guard let stats = stats
        else {
            
            if alpha != 0 {
                
                UIView.animate(withDuration: 0.39,
                               delay: 0) {
                    
                    self.alpha = 0.0
                    
                }
                
            }
            
            return /*EXIT*/
            
        }
        
        uiInit(with: stats)
        
        if alpha != 0.75 {
            
            UIView.animate(withDuration: 0.8,
                           delay: 0,
                           options: UIView.AnimationOptions.curveEaseIn) {
                
                self.alpha = 0.8
                
            }
            
        }
                
    }
    
    private func uiInit(with stats: DailyStats) {
        
        dateLabel.text  = stats.date.simple
        stat1Label.text = "\(stats.rank.0.delimited) of \(stats.rank.1.delimited)"
        stat2Label.text = stats.averageScore.delimited
        stat3Label.text = stats.gameCount.delimited
        
        averageLevelLabel.layer.borderWidth = 1
        averageLevelLabel.layer.cornerRadius = 3
        averageLevelLabel.textColor = .black
        averageLevelLabel.layer.borderColor = UIColor.black.cgColor
        averageLevelLabel.backgroundColor = .white
        
        averageLevelBGView.backgroundColor = UIColor(named: "Pink")
        averageLevelBGView.layer.borderWidth = 2.5
        averageLevelBGView.layer.borderColor = UIColor(named:"Banana")!.cgColor
        averageLevelBGView.setRadius()
        
        averageLevelIconImageView.image = Score.iconFor(level: stats.averageLevel)
        
        Utils.UI.addShadows(to: averageLevelContainerView)
        averageLevelContainerView.rotateRandom(minAngle: -5, maxAngle: 5)
        
    }
    
}