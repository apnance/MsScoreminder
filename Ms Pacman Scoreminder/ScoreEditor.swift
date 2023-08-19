//
//  ScoreEditor.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 8/11/23.
//

import UIKit
import APNUtil
import APNFlexKeypad

class ScoreEditor: UIView {
    
    @IBOutlet weak var scoreContainerView: UIView!
    @IBOutlet weak var numPad: APNFlexKeypad!
    @IBOutlet weak var fruitPad: APNFlexKeypad!
    @IBOutlet weak var semiOpaqueBGView: UIView!
        
    private let blue    = UIColor(named: "Blue")!
    private let pink    = UIColor(named: "Pink")!
    private let apple   = UIColor(named: "Apple")!
    private let pear    = UIColor(named: "Pear")!
    private let banana  = UIColor(named: "Banana")!
    private let orange  = UIColor(named: "Orange")!
    private let white   = UIColor.white

    
    func uiInit() {
        
        numPad.build(withConfigs: APNFlexKeypadConfigs(delegate: self,
                                                        keys: [   1: ("1",  .accumulator("1"),      blue,   white)
                                                                , 2: ("2",  .accumulator("2"),      blue,   white)
                                                                , 3: ("3",  .accumulator("3"),      blue,   white)
                                                                , 4: ("4",  .accumulator("4"),      blue,   white)
                                                                , 5: ("5",  .accumulator("5"),      blue,   white)
                                                                , 6: ("6",  .accumulator("6"),      blue,   white)
                                                                , 7: ("7",  .accumulator("7"),      blue,   white)
                                                                , 8: ("8",  .accumulator("8"),      blue,   white)
                                                                , 9: ("9",  .accumulator("9"),      blue,   white)
                                                                , 10: ("<", .accumulatorBackspace,  orange, white)
                                                                , 11: ("0", .accumulatorPost("0"),  blue,   white)
                                                                , 12: ("X", .accumulatorReset,      apple,  white)
                                                              ]))
        
        fruitPad.build(withConfigs: APNFlexKeypadConfigs(delegate: self,
                                                        keys: [     1: ("ms_icon_0",  .singleValue("0"), blue, white)
                                                                  , 2: ("ms_icon_1",  .singleValue("1"), blue, white)
                                                                  , 3: ("ms_icon_2",  .singleValue("2"), blue, white)
                                                                  , 4: ("ms_icon_3",  .singleValue("3"), blue, white)
                                                                  , 5: ("ms_icon_4",  .singleValue("4"), blue, white)
                                                                  , 6: ("ms_icon_5",  .singleValue("5"), blue, white)
                                                                  , 7: ("ms_icon_6",  .singleValue("6"), blue, white)
                                                                  , 8: ("+", .custom({ [weak self] in self?.addBanana() }), banana, blue)
                                                              ]))
        
        scoreContainerView.backgroundColor  = .clear
        
        fruitPad.layer.cornerRadius         = fruitPad.frame.height / 2.0
        fruitPad.backgroundColor            = orange
        
        numPad.layer.cornerRadius           = numPad.frame.width / 2.0
        numPad.backgroundColor              = pink
        
        loadScore()
        
        numPad.show(false,      animated: false)
        fruitPad.show(false,    animated: false)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleKeypads))
        
        semiOpaqueBGView.addGestureRecognizer(tap)
        
    }

    private func addBanana() {
        
        let fruitVal = String(min(14,(Int(fruitPad.value) ?? 0) + 1))
        
        fruitPad.set(value: fruitVal)
        
    }
    
    @objc private func toggleKeypads() {
        
        numPad.show(!numPad.isShown, animated: true)

        reconcileFruitpad()
        
//        if !numPad.isShown {
//            fruitPad.show(false, animated: true)
//        }
        
    }

    
}

extension ScoreEditor: APNFlexKeypadDelegate {
    
    func valueChanged(_ value: String?) {
                
        loadScore()
        
    }
    
    func showHideComplete(isShown: Bool) {
  
// TODO: Clean Up - delete
//        if !isShown {
//
//            UIView.animate(withDuration: 0.4) {
////                self.uiContainerView.alpha = 0.0
//
//            }
//
//        }
        
    }
    
    func showHideBegin(isShown: Bool) {
        
// TODO: Clean Up - delete
//        if !isShown {
//
//            UIView.animate(withDuration: 0.2) {
//
////                self.uiContainerView.alpha = 1.0
//
//            }
//
//        }
        
    }
    
    
    private func loadScore() {
        
        let scoreValue = Int(numPad.value) ?? 0
        let levelValue = Int(fruitPad.value) ?? 0
        
        let score = Score(date: Date.now, score: Int(scoreValue), level: levelValue)
        
        let scoreView   = AtomicScoreView.new(delegate: nil,
                                              withScore: score,
                                              andData: [""])
        
        scoreContainerView.removeAllSubviews()
        scoreContainerView.translatesAutoresizingMaskIntoConstraints = true
        scoreContainerView.addSubview(scoreView)
        

        reconcileFruitpad()
        
// TODO: Clean Up - Implement saving of score - saving these scores in this manner causes runtime error when running the original VC with Scoreminder UI
//        if scoreValue % 10 == 0 && scoreValue > 0 {
//
//            var statMan = StatManager()
//            statMan.set(Score(date: Date(),
//                              score: scoreValue,
//                              level: levelValue))
//
//        }
        
        scoreView.center = scoreContainerView.frame.center
        
    }
    
    func reconcileFruitpad() {
        
        let scoreValue = Int(numPad.value) ?? 0
        
        if numPad.isShown && numPad.value != "" && scoreValue % 10 == 0 {
            
            fruitPad.show(true, animated: true)
            
        } else {
            
            fruitPad.show(false, animated: true)
            
        }

    }

    
}

protocol ScoreEditorDelegate {
    
    func delete(score:Score)
    func set(score: Score)
    
}
