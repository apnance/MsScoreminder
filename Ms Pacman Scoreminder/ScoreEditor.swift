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
    
    @IBOutlet weak var semiOpaqueBGView: UIView!
    @IBOutlet weak var uiContainerView: UIView!
    @IBOutlet weak var scoreContainerView: UIView!
    @IBOutlet weak var numPad: APNFlexKeypad!
    @IBOutlet weak var fruitPad: APNFlexKeypad!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var editScoreLabel: UILabel!
    
    @IBAction func tappedDelete(_ sender: Any) { delegate?.delete(score: score) }
    @IBAction func tappedSet(_ sender: Any) { delegate?.set(score: score); hide() }
    @IBAction func decreasLevel(_ sender: Any) { changeLevel(-1) }
    @IBAction func increaseLevel(_ sender: Any) { changeLevel(+1) }
    
    /// The focus and raison d'etre of the ScoreEditor control.
    private(set) var score: Score = .zero
    
    /// The top level view of the control.
    private(set) var view: ScoreEditor?
    
    private(set) var delegate: ScoreEditorDelegate?
    
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
    
    // TODO: Clean Up - factor init(superView: delegate:) into sub-methods.
    init(superView: UIView, delegate: ScoreEditorDelegate? = nil) {
        
        super.init(frame: .zero)
        
        self.delegate = delegate
        
        view = (Bundle.main.loadNibNamed("ScoreEditor",
                                         owner: self,
                                         options: nil)?.first as? UIView) as? ScoreEditor
            
        view?.constrainIn(superView)
        
        numPad.build(withConfigs: APNFlexKeypadConfigs(id: "numPad",
                                                       delegate: self,
                                                       keys: [   1: ("1",       .accumulator("1"),      Colors.blue,   Colors.white)
                                                                 , 2: ("2",     .accumulator("2"),      Colors.blue,   Colors.white)
                                                                 , 3: ("3",     .accumulator("3"),      Colors.blue,   Colors.white)
                                                                 , 4: ("4",     .accumulator("4"),      Colors.blue,   Colors.white)
                                                                 , 5: ("5",     .accumulator("5"),      Colors.blue,   Colors.white)
                                                                 , 6: ("6",     .accumulator("6"),      Colors.blue,   Colors.white)
                                                                 , 7: ("7",     .accumulator("7"),      Colors.blue,   Colors.white)
                                                                 , 8: ("8",     .accumulator("8"),      Colors.blue,   Colors.white)
                                                                 , 9: ("9",     .accumulator("9"),      Colors.blue,   Colors.white)
                                                                 , 10: ("0",    .accumulatorPost("0"),  Colors.blue,   Colors.white)
                                                                 , 11: ("<",    .accumulatorBackspace,  Colors.white,  Colors.blue)
                                                                 , 12: ("X",    .accumulatorReset,      Colors.white,  Colors.apple)
                                                             ])
                     ,buttonStyler: outlineAndShadow(view:))
        
        fruitPad.build(withConfigs: APNFlexKeypadConfigs(id: "fruitPad",
                                                         delegate: self,
                                                         keys: [     1: ("ms_icon_0",  .singleValue("0"),   Colors.blue, Colors.white)
                                                                     , 2: ("ms_icon_1",  .singleValue("1"), Colors.blue, Colors.white)
                                                                     , 3: ("ms_icon_2",  .singleValue("2"), Colors.blue, Colors.white)
                                                                     , 4: ("ms_icon_3",  .singleValue("3"), Colors.blue, Colors.white)
                                                                     , 5: ("ms_icon_4",  .singleValue("4"), Colors.blue, Colors.white)
                                                                     , 6: ("ms_icon_5",  .singleValue("5"), Colors.blue, Colors.white)
                                                                     , 7: ("ms_icon_6",  .singleValue("6"), Colors.blue, Colors.white)
                                                                     , 8: ("+", .custom({ [weak self] in self?.changeLevel(+1) }), Colors.banana, Colors.blue)
                                                               ]))
        
        uiContainerView.layer.borderColor   = Colors.banana.cgColor
        uiContainerView.layer.borderWidth   = 1.5
        uiContainerView.layer.cornerRadius  = 10
        uiContainerView.backgroundColor     = Colors.blue
        
        scoreContainerView.backgroundColor  = .clear
        scoreContainerView.alpha            = 0.0
        
        fruitPad.layer.cornerRadius         = fruitPad.frame.height / 2.0
        fruitPad.backgroundColor            = Colors.pretzel
        outlineAndShadow(view: fruitPad)
        
        fruitPad.show(false,    animated: false)
        
        numPad.layer.cornerRadius           = numPad.frame.width / 2.0
        numPad.backgroundColor              = Colors.pink
        let borderView = UIView(frame: .zero)
        borderView.constrainIn(numPad)
        numPad.sendSubviewToBack(borderView)
        borderView.backgroundColor      = .clear
        borderView.layer.borderWidth    = numPad.frame.width * 0.04
        borderView.layer.borderColor    = Colors.banana.cgColor
        borderView.layer.cornerRadius   = numPad.layer.cornerRadius
        numPad.show(false,      animated: false)
        
        Utils.UI.outlineLabel(editScoreLabel)
        addShadows()
        
        // Hide
        view?.alpha = 0.0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hide))
        semiOpaqueBGView.addGestureRecognizer(tap)
        
    }
    
    /// Changes current fruitPad.value by the incr value, clamping values between 0-14
    /// - Parameter incr: amount to increase or decreas fruitPad.value by.
    private func changeLevel(_ incr: Int) {
        
        if incr > 0 {
            
            fruitPad.set(value: String(min(14, (Int(fruitPad.value) ?? 0) + incr)))
            
        } else {
            
            fruitPad.set(value: String(max(0, (Int(fruitPad.value) ?? 0) + incr)))
        }
        
        load()
        
    }
    
    /// Hides the ScoreEditor control in its superview.  Effectively dismisses the control.
    @objc private func hide() {
        
        numPad.show(false, animated: true)
        uiReconcileFruitPad()
        
        UIView.animate(withDuration: Configs.UI.Timing.ScoreEditor.hideDuration,
                       delay: 0.0,
                       options: [.allowUserInteraction]) { self.view?.alpha = 0.0 }
        
    }
    
    /// Shows or summons the ScoreEditor control in its superView.
    func show() {
        
        updateButton.isHidden = score.score % 10 != 0
        
        UIView.animate(withDuration: Configs.UI.Timing.ScoreEditor.showDuration,
                       delay: 0.0,
                       options: [.allowUserInteraction]) { self.view?.alpha = 1.0 }
        
        numPad.show(true, animated: true)
        uiReconcileFruitPad()
    }
    
    /// Adds a fine gray outline and drop shadow to specified `UIView`
    private func outlineAndShadow(view: UIView) {
        
        view.addShadows(withOpacity: 0.2)
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.pointOneAlpha.cgColor
        
    }
    
    /// Adds drop shadows to assorted UI elements.
    private func addShadows() {
        
        Utils.UI.addShadows(to: [editScoreLabel,
                                 numPad])
        
    }
}

// - MARK: APNFlexKeypadDelegate
extension ScoreEditor: APNFlexKeypadDelegate {
    
    func valueChanged(_ value: String?,
                      forID id: String) { load() }
    
    func showHideComplete(forID id: String, isShown: Bool, animated: Bool) {
        
        if id == numPad.id {
            
            if animated {
                
                UIView.animate(withDuration: 0.125) {
                    
                    self.scoreContainerView.alpha = self.numPad.isShown ? 1.0 : 0.0
                    
                }
                
            } else {
                
                scoreContainerView.alpha = self.numPad.isShown ? 1.0 : 0.0
                
            }
            
        }
        
    }
    
    func showHideBegin(forID id: String,
                       isShown: Bool) { /*DO NOTHING*/ }
    
    func load(score newScore: Score? = nil) {
        
        if let newScore = newScore {
            
            score = newScore
            numPad.set(value:   newScore.score.description)
            fruitPad.set(value: newScore.level.description)
            
        } else {
            
            score.score = Int(numPad.value) ?? 0
            score.level = Int(fruitPad.value) ?? 0
            
        }
        
        let scoreView   = AtomicScoreView.new(delegate: nil,
                                              withScore: score,
                                              andData: [""])
        
        scoreView.isUserInteractionEnabled = false
        
        scoreContainerView.subviews.forEach { if $0 is AtomicScoreView { $0.removeFromSuperview() } }
        scoreContainerView.translatesAutoresizingMaskIntoConstraints = true
        scoreContainerView.addSubview(scoreView)
        
        Utils.UI.addShadows(to: scoreView)
        
        show()
        
        assert(scoreContainerView.subviews.count <= 3,
               """
                    Max number of expected subviews(3) exceeded for scoreContainerView.
                    Are you removing old views before adding a new one?")
                """)
        
        scoreView.center = scoreContainerView.frame.center
        
    }
    
    
    /// Manages the display of fruitPad as approrpriate
    func uiReconcileFruitPad() {
        
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
