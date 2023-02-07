//
//  DailyHighlightsView.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 10/29/21.
//

import UIKit
import APNUtil

class DailyHighlightsView: RoundView {
    
    private var stats: DailyStatCluster
    
    private var statsArray: [DailyStats] {
        
        var statsArray = [DailyStats]()
        
        if let requested = stats.requested { statsArray.append(requested) }
        
        if let high = stats.high { statsArray.append(high) }
        
        if let low = stats.low { statsArray.append(low) }
            
        return statsArray
        
    }
    
    private var currStats = 0
    private var initialized: Bool = false
    var shouldCycle = false
    
    // MARK: - Outlets
    @IBOutlet weak var dateLabel: UILabel!
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
    func load(_ stats: DailyStatCluster) {
        self.stats = stats
        self.currStats = 0
        
        if !initialized {
            
            initialized = true
                    
            let tap = UITapGestureRecognizer(target: self,
                                             action: #selector(cycle))
            self.addGestureRecognizer(tap)
            
        }
        
        cycle()
        
    }
    
    @objc private func cycle() {
        
        uiInit()
        
        if !shouldCycle { return /*EXIT*/ }
        
        if stats.requested == nil && stats.high == nil && stats.low == nil {
            
            if alpha != 0 {
                
                UIView.animate(withDuration: Configs.UI.Timing.RoundViewInfo.fadeTime,
                               delay: 0) {
                    
                    self.alpha = 0.0
                    
                }
                
            }
            
            return /*EXIT*/
            
        }
        
        if alpha != 0.75 {
            
            UIView.animate(withDuration: 0.8,
                           delay: 0.0,
                           options: UIView.AnimationOptions.curveEaseIn,
                           animations: { self.alpha = 0.8 } )
            
        }
        
    }
    
    private func uiInit() {
        
        // reset counter?
        currStats = currStats > statsArray.lastUsableIndex ? 0 : currStats
        
        let stats = statsArray[currStats]
        
        dateLabel.text  = stats.date.simple
        stat1Label.text = getRankText(stats)
        stat2Label.text = stats.averageScore.delimited
        stat3Label.text = stats.gamesPlayed.delimited
        
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
        
        bestDayContainerView.alpha  = 1.0
        bestDayStarLabel.alpha      = stats.rank.0 <= 10 ? 1.0 : 0.0
        
        bestDayRank.text            = stats.rank.0.description
        
        Utils.UI.addShadows(to: averageLevelContainerView)
        averageLevelContainerView.rotateRandom(minAngle: 5, maxAngle: 8)
        
        // advance counter
        currStats += 1
        
    }
    
    private func getRankText(_ stats: DailyStats) -> String {
        
        let percentile = StatManager.percentileDescription(stats.rank)
        let output = "\(stats.rank.0.delimited)/\(stats.rank.1.delimited) (\(percentile))"
        
        return output
        
    }
    
}