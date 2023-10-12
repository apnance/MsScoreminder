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
    
    // MARK: - Outlets
    @IBOutlet weak var semiOpaqueBGView: UIView!
    @IBOutlet weak var uiContainerView: UIView!
    @IBOutlet weak var polkaDotsView: UIView!
    @IBOutlet weak var scoreContainerView: UIView!
    @IBOutlet weak var deleteConfirmationContainerView: UIView!
    @IBOutlet weak var numPad: APNFlexKeypad!
    @IBOutlet weak var fruitPad: APNFlexKeypad!
    @IBOutlet weak var deleteButton: RoundButton!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var editScoreLabel: UILabel!
    
    // MARK: - Actions
    @IBAction func tapShowDeleteConfirmation(_ sender: Any) {
        
        deleteConfirmation(show: true)
        
    }
    
    @IBAction func tappedDelete(_ sender: UIButton) {
        
        if sender.tag == 1 {
            
            delete()
            
        } else {
            
            deleteConfirmation(show: false)
            
        }
        
    }
    
    @IBAction func tappedSet(_ sender: Any) { set() }
    @IBAction func decreasLevel(_ sender: Any) { changeLevel(-1) }
    @IBAction func increaseLevel(_ sender: Any) { changeLevel(+1) }
    
    
    // MARK: - Properties
    /// The focus and raison d'etre of the ScoreEditor control.
    private(set) var score: Score = .zero {
        
        willSet {
            
            // TODO: Clean Up - Factor this show/hide logic out into a uiShowUpdateDelete()
            let isUpdatable = (newValue != lastSavedScore) && (newValue.score % 10 == 0)
            
            // Show/hide UI
            updateButton.isHidden = !isUpdatable
            deleteButton.isHidden = newValue != lastSavedScore
            
        }
        
    }
    
    /// Score used to track the last saved score, this value will be sent to delegate.delete(score:) if user taps to delete or updates the score.
    /// When a score is "updated" the old value is first deleted then the new value is set.
    private var lastSavedScore: Score?
    
    /// The top level view of the control.
    private(set) var view: ScoreEditor?
    
    /// Delegate object
    private(set) var delegate: ScoreEditorDelegate?
    
    
    // MARK: - Custom Methods
    required init?(coder: NSCoder) { super.init(coder: coder) }
    
    /// Initializes a new ScoreEditor placing the control in `superView.subviews` and constraining it to fill superview.
    /// - Parameters:
    ///   - superView: `UIView` into which ScoreEditor should be loaded and constrained.
    ///   - delegate: Delegate object to receive ScoreEditorDelegate methods calls.
    init(superView: UIView, delegate: ScoreEditorDelegate? = nil) {
        
        super.init(frame: .zero)
        self.delegate = delegate
        
        // View
        view = (Bundle.main.loadNibNamed("ScoreEditor",
                                         owner: self,
                                         options: nil)?.first as? UIView) as? ScoreEditor
        view?.constrainIn(superView)
        view?.alpha = 0.0
        
        uiInitDeleteConfirmation()
        uiInitNumPad()
        uiInitFruitPad()
        uiInitContainerViews()
        uiInitEditScoreLabel()
        
        // Gestures
        let tap = UITapGestureRecognizer(target: self, action: #selector(hide))
        semiOpaqueBGView.addGestureRecognizer(tap)
        
    }
    
    // -MARK: UI
    private func uiInitDeleteConfirmation() {
        
        deleteConfirmationContainerView.subviews.forEach {
            self.outlineAndShadow(view: $0)
            
        }
        
        deleteConfirmation(show: false)
        
    }
    
    private func uiInitNumPad() {
        numPad.build(withConfigs: APNFlexKeypadConfigs(id: "numPad",
                                                       delegate: self,
                                                       keys: [   1: ("1",       .accumulator("1"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 2: ("2",     .accumulator("2"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 3: ("3",     .accumulator("3"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 4: ("4",     .accumulator("4"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 5: ("5",     .accumulator("5"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 6: ("6",     .accumulator("6"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 7: ("7",     .accumulator("7"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 8: ("8",     .accumulator("8"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 9: ("9",     .accumulator("9"),      Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 10: ("0",    .accumulatorPost("0"),  Colors.blue,   Colors.white, Colors.banana, .light)
                                                                 , 11: ("<",    .accumulatorBackspace,  Colors.white,  Colors.blue, Colors.pear,  .medium)
                                                                 , 12: ("X",    .accumulatorReset,      Colors.white,  Colors.apple, Colors.pear, .heavy)
                                                             ])
                     ,buttonStyler: outlineAndShadow(view:))
        
        numPad.layer.cornerRadius       = numPad.frame.width / 2.0
        numPad.backgroundColor          = Colors.pink
        let borderView = UIView(frame: .zero)
        borderView.constrainIn(numPad)
        numPad.sendSubviewToBack(borderView)
        borderView.backgroundColor      = .clear
        borderView.layer.borderWidth    = numPad.frame.width * 0.04
        borderView.layer.borderColor    = Colors.banana.cgColor
        borderView.layer.cornerRadius   = numPad.layer.cornerRadius
        Utils.UI.addShadows(to: numPad)
        numPad.show(false,      animated: false)
        
    }
    
    private func uiInitFruitPad() {
        fruitPad.build(withConfigs: APNFlexKeypadConfigs(id: "fruitPad",
                                                         delegate: self,
                                                         keys: [     1: ("ms_icon_0",  .singleValue("0"),   Colors.blue, Colors.white, Colors.banana, .medium)
                                                                     , 2: ("ms_icon_1",  .singleValue("1"), Colors.blue, Colors.white, Colors.banana, .medium)
                                                                     , 3: ("ms_icon_2",  .singleValue("2"), Colors.blue, Colors.white, Colors.banana, .medium)
                                                                     , 4: ("ms_icon_3",  .singleValue("3"), Colors.blue, Colors.white, Colors.banana, .medium)
                                                                     , 5: ("ms_icon_4",  .singleValue("4"), Colors.blue, Colors.white, Colors.banana, .medium)
                                                                     , 6: ("ms_icon_5",  .singleValue("5"), Colors.blue, Colors.white, Colors.banana, .medium)
                                                                     , 7: ("ms_icon_6",  .singleValue("6"), Colors.blue, Colors.white, Colors.banana, .medium)
                                                                     , 8: ("+", .custom({ [weak self] in self?.changeLevel(+1) }), Colors.banana, Colors.blue, Colors.banana, .medium)
                                                               ]))
        
        fruitPad.layer.cornerRadius         = fruitPad.frame.height / 2.0
        fruitPad.backgroundColor            = Colors.pretzel
        outlineAndShadow(view: fruitPad)
        fruitPad.show(false,    animated: false)
        
    }
    
    private func uiInitContainerViews() {
        
        uiContainerView.layer.borderColor   = Colors.banana.cgColor
        uiContainerView.layer.borderWidth   = 1.5
        uiContainerView.layer.cornerRadius  = 10
        uiContainerView.backgroundColor     = Colors.blue
        
        polkaDotsView.backgroundColor       = UIColor(patternImage: UIImage(named: "PolkaDotsWhiteDark")!)
        
        scoreContainerView.backgroundColor  = .clear
        scoreContainerView.alpha            = 0.0
        
    }
    
    private func uiInitEditScoreLabel() {
        
        Utils.UI.outlineLabel(editScoreLabel)
        Utils.UI.addShadows(to: editScoreLabel)
        
    }
    
    /// Displays/hides a delete confirmation UI
    func deleteConfirmation(show: Bool) {
        
        editScoreLabel.text = show ? Configs.UI.Text.ScoreEditor.delete :  Configs.UI.Text.ScoreEditor.edit
        deleteConfirmationContainerView.isHidden = !show
        
        numPad.hideButtons(show)
        fruitPad.isHidden   = show
        
    }
    
    /// Loads a new score from argument or creates a new score from numPad/fruitPad values.
    func load(score newScore: Score? = nil, isDeletable: Bool = false) {
        
        if let newScore = newScore { // Score was loaded into ScoreEditor
            
            lastSavedScore  = isDeletable ? newScore : nil
            editScoreLabel.text = isDeletable ? Configs.UI.Text.ScoreEditor.edit : Configs.UI.Text.ScoreEditor.enter
            score           = newScore
            numPad.set(value:   newScore.score.description)
            fruitPad.set(value: newScore.level.num.description)
            
        } else {
            
            score.score = Int(numPad.value) ?? 0
            score.level = Level.get(Int(fruitPad.value) ?? 0)
            
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
    
    /// Passes `score` to delegate.set(score:)
    private func set() {
        
        if score != lastSavedScore {
            
            delegate?.set(new: score, replacing: lastSavedScore)
            
            hide()
            
        }
        
    }
    
    /// Passes non-nil `lastSavedScore` values to to delegate.delete(score:)
    private func delete() {
        
        if let toDelete = lastSavedScore {
            
            delegate?.delete(score: toDelete)
            
            hide()
            
        }
        
    }
    
    /// Hides the ScoreEditor control in its superview.  Effectively dismisses the control.
    @objc private func hide() {
        
        lastSavedScore = nil
        
        numPad.show(false, animated: true)
        uiReconcileFruitPad()
        
        delegate?.cleanUp()
        
        UIView.animate(withDuration: Configs.UI.Timing.ScoreEditor.hideDuration,
                       delay: 0.0,
                       options: [.allowUserInteraction]) { self.view?.alpha = 0.0 } completion: { success in
            
            self.deleteConfirmation(show: false)
            
        }
        
    }
    
    /// Shows or summons the ScoreEditor control in its superView.
    func show() {
        
        if view?.alpha != 1.0 {
            
            UIView.animate(withDuration: Configs.UI.Timing.ScoreEditor.showDuration,
                           delay: 0.0,
                           options: [.allowUserInteraction]) { self.view?.alpha = 1.0 }
            
        }
        
        numPad.show(true, animated: true)
        uiReconcileFruitPad()
        
    }
    
    /// Adds a fine gray outline and drop shadow to specified `UIView`
    private func outlineAndShadow(view: UIView) {
        
        view.addShadows(withOpacity: 0.2)
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.pointOneAlpha.cgColor
        
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
    
}

protocol ScoreEditorDelegate {
    
    /// Called as `ScoreEditor` is dismissed.
    func cleanUp()
    
    /// Called when user attempts to delete a `Score`
    ///
    /// - Parameters:
    /// - score: `Score` to delete
    func delete(score: Score)
    
    /// Called when user updates or add a new `Score`
    ///
    /// - Parameters:
    /// - new:The new `Score` or updated value.
    /// - replacing: The old value to be replaced with `new`
    func set(new: Score, replacing: Score?)
    
}
