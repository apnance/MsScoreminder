//
//  DailyHighlightsView.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/29/21.
//

import UIKit
import APNUtil

class DailyHighlightsView: RoundTextView {
    
    private var initialized: Bool = false
    var shouldCycle = false
    private var dailyStats = DailyStatsCluster()
    
    // MARK: - Outlets
    @IBOutlet weak var roundDateView: RoundTextView!
    @IBOutlet weak var stat1Label: UILabel!
    @IBOutlet weak var stat2Label: UILabel!
    @IBOutlet weak var stat3Label: UILabel!
    
    @IBOutlet weak var averageLevelContainerView: UIView!
    @IBOutlet weak var averageLevelBGView: RoundView!
    @IBOutlet weak var averageLevelIconImageView: UIImageView!
    @IBOutlet weak var averageLevelLabel: UILabel!
    @IBOutlet weak var bestDayContainerView: UIView!
    @IBOutlet weak var bestDayStarLabel: UILabel!
    @IBOutlet weak var bestDayRank: UILabel!
    
    
    // MARK: - Overrides
    override func awakeAfter(using coder: NSCoder) -> Any? {
        
        if subviews.count == 0 {
            
            let nib = UINib(nibName: "DailyHighlightsView",
                                           bundle: Bundle.main)
            
            let view = nib.instantiate(withOwner: nil,
                                       options: nil).first as! DailyHighlightsView
            
            view.frame = self.frame
            view.autoresizingMask = self.autoresizingMask
            view.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints
            
            view.rotate(angle: Configs.UI.Rotations.summaryView)
            
            view.alpha = 0
            
            return view
            
        }
        
        return self
        
    }
    
    
    // MARK: - Custom Methods
    func load(_ stats: DailyStatsCluster) {
        
        self.dailyStats = stats
        
        if !initialized {
            
            initialized = true
                    
            let tap = UITapGestureRecognizer(target: self,
                                             action: #selector(uiInit))
            self.addGestureRecognizer(tap)
            
        }
        
        uiInit()
        
    }
    
    @objc private func uiInit() {
        
        let stats = dailyStats.getNext()
        
        roundDateView.set(text: stats.date.simple)
        stat1Label.text = getRankText(stats)
        stat2Label.text = stats.averageScore.delimited
        stat3Label.text = stats.gamesPlayed.delimited
        
        averageLevelLabel.layer.borderWidth     = 1
        averageLevelLabel.layer.cornerRadius    = 3
        averageLevelLabel.textColor             = .black
        averageLevelLabel.layer.borderColor     = UIColor.black.cgColor
        averageLevelLabel.backgroundColor       = .white
        
        averageLevelBGView.backgroundColor      = .msPink
        averageLevelBGView.layer.borderWidth    = 2.5
        averageLevelBGView.layer.borderColor    = UIColor.banana.cgColor
        averageLevelBGView.setRadius()
        
        averageLevelIconImageView.image = Level.get(stats.averageLevel).icon
        
        bestDayContainerView.alpha  = 1.0
        bestDayStarLabel.alpha      = stats.rank.0 <= 10 ? 1.0 : 0.0
        
        bestDayRank.text            = stats.rank.0.description
        
        Utils.UI.addShadows(to: averageLevelContainerView)
        averageLevelContainerView.rotateRandom(minAngle: 5, maxAngle: 8)
        
    }
    
    private func getRankText(_ stats: DailyStats) -> String {
        
        let percentile = StatManager.percentileDescription(stats.rank)
        let output = "\(stats.rank.0.delimited)/\(stats.rank.1.delimited) (\(percentile))"
        
        return output
        
    }
    
}
