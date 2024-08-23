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
    var score: Score = .zero { willSet { uiShowUpdateDelete(newValue) } }
    
    /// Score used to track the last saved score, this value will be sent to delegate.delete(score:) if user taps to delete or updates the score.
    /// When a score is "updated" the old value is first deleted then the new value is set.
    private var lastSavedScore: Score?
    
    /// The top level view of the control.
    private(set) var view: ScoreEditor?
    
    /// Delegate object
    private(set) var delegate: ScoreEditorDelegate?
    
    /// Flag to toggle predictive level selection
    private var shouldPredictLevel = false
    
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
        
        uiInitGen()
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
    private func uiInitGen() {
        
        Utils.UI.addShadows(to: [deleteButton, updateButton], 
                            withOpacity: 0.3)
        
    }
    
    /// Shows/hides update/delete buttons as user changes the score editor's score value.
    /// - Parameter newValue: value entered into score editor
    private func uiShowUpdateDelete(_ newValue: Score) {
        
        let isUpdatable = (newValue != lastSavedScore) && (newValue.score % 10 == 0)
        
        // Show/hide UI
        updateButton.isHidden = !isUpdatable
        deleteButton.isHidden = newValue != lastSavedScore
        
    }
    
    private func uiInitDeleteConfirmation() {
        
        deleteConfirmationContainerView.subviews.forEach {
            self.outlineAndShadow(view: $0)
            
        }
        
        deleteConfirmation(show: false)
        
    }
    
    private func uiInitNumPad() {
        
        let numColors       = Configs.UI.Colors.ScoreEditor.NumPad.numKeys
        let backColors      = Configs.UI.Colors.ScoreEditor.NumPad.backKey
        let resetColors     = Configs.UI.Colors.ScoreEditor.NumPad.resetKey
        
        numPad.build(withConfigs: APNFlexKeypadConfigs(id: "numPad",
                                                       delegate: self,
                                                       defaultFont:  Configs.UI.Fonts.ScoreEditor.default,
                                                       keys: [
                                                                1: ("1",    .accumulator("1"),      numColors,      nil, .light),
                                                                2: ("2",    .accumulator("2"),      numColors,      nil, .light),
                                                                3: ("3",    .accumulator("3"),      numColors,      nil, .light),
                                                                4: ("4",    .accumulator("4"),      numColors,      nil, .light),
                                                                5: ("5",    .accumulator("5"),      numColors,      nil, .light),
                                                                6: ("6",    .accumulator("6"),      numColors,      nil, .light),
                                                                7: ("7",    .accumulator("7"),      numColors,      nil, .light),
                                                                8: ("8",    .accumulator("8"),      numColors,      nil, .light),
                                                                9: ("9",    .accumulator("9"),      numColors,      nil, .light),
                                                                10: ("0",   .accumulatorPost("0"),  numColors,      nil, .light),
                                                                11: ("⌫",   .accumulatorBackspace,  backColors,     Configs.UI.Fonts.ScoreEditor.back, .medium),
                                                                12: ("✘",   .accumulatorReset,      resetColors,    Configs.UI.Fonts.ScoreEditor.reset, .heavy)
                                                                
                                                             ])
                     ,buttonStyler: outlineAndShadow(view:))
        
        numPad.layer.cornerRadius       = numPad.frame.width / 2.0
        numPad.backgroundColor          = Configs.UI.Colors.ScoreEditor.NumPad.bg
        
        let borderView = UIView(frame: .zero)
        borderView.constrainIn(numPad)
        numPad.sendSubviewToBack(borderView)
        borderView.backgroundColor      = .clear
        borderView.layer.borderWidth    = numPad.frame.width * 0.04
        borderView.layer.borderColor    = Configs.UI.Colors.ScoreEditor.border.cgColor
        
        borderView.layer.cornerRadius   = numPad.layer.cornerRadius
        Utils.UI.addShadows(to: numPad)
        numPad.show(false,      animated: false)
        
    }
    
    private func uiInitFruitPad() {
        
        let fruitColors = Configs.UI.Colors.ScoreEditor.FruitPad.regKeys
        let plusColors  = Configs.UI.Colors.ScoreEditor.FruitPad.plusKey
        
        fruitPad.build(withConfigs: APNFlexKeypadConfigs(id: "fruitPad",
                                                         delegate: self,
                                                         defaultFont: Configs.UI.Fonts.ScoreEditor.default,
                                                         keys: [     1: ("ms_icon_0",   .singleValue("0"),  fruitColors, nil, .medium),
                                                                     2: ("ms_icon_1", .singleValue("1"),    fruitColors, nil, .medium),
                                                                     3: ("ms_icon_2", .singleValue("2"),    fruitColors, nil, .medium),
                                                                     4: ("ms_icon_3", .singleValue("3"),    fruitColors, nil, .medium),
                                                                     5: ("ms_icon_4", .singleValue("4"),    fruitColors, nil, .medium),
                                                                     6: ("ms_icon_5", .singleValue("5"),    fruitColors, nil, .medium),
                                                                     7: ("ms_icon_6", .singleValue("6"),    fruitColors, nil, .medium),
                                                                     8: ("✚", .custom({ [weak self] in self?.changeLevel(+1) }),
                                                                           plusColors, nil, .medium)
                                                               ]))
        
        fruitPad.layer.cornerRadius = fruitPad.frame.height / 2.0
        fruitPad.backgroundColor    = Configs.UI.Colors.ScoreEditor.FruitPad.bg
        
        outlineAndShadow(view: fruitPad)
        fruitPad.show(false,    animated: false)
        
    }
    
    private func uiInitContainerViews() {
        
        uiContainerView.backgroundColor     = Configs.UI.Colors.ScoreEditor.UIContainer.bg
        uiContainerView.layer.borderColor   = Configs.UI.Colors.ScoreEditor.UIContainer.border.cgColor
        
        uiContainerView.layer.borderWidth   = 1.5
        uiContainerView.layer.cornerRadius  = 10
        
        polkaDotsView.backgroundColor       = Configs.UI.Colors.ScoreEditor.UIContainer.polkaDotsBG
        
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
    
    private func highlightFruitButton(_ num: Int) {
        
        fruitPad.highlight(buttonNum: min(num, banana1))
        
    }
    
    /// Loads a new score from argument or creates a new score from numPad/fruitPad values.
    func load(score newScore: Score? = nil, isDeletable: Bool = false) {
        
        if let newScore = newScore { // Score was loaded into ScoreEditor
            
            shouldPredictLevel  = newScore == Score.zero
            lastSavedScore      = isDeletable ? newScore : nil
            editScoreLabel.text = isDeletable ? Configs.UI.Text.ScoreEditor.edit : Configs.UI.Text.ScoreEditor.enter
            score               = newScore
            numPad.set(value:   newScore.score.description)
            fruitPad.set(value: newScore.level.num.description)
            
        } else {
            
            score.score = Int(numPad.value) ?? 0
            score.level = getLevelFor(score.score)
            fruitPad.set(value: score.level.num.description)
            
        }
        
        // Highlight
        highlightFruitButton(score.level.num)
        
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
        
        shouldPredictLevel = false
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        if incr > 0 {
            
            fruitPad.set(value: String(min(14, (Int(fruitPad.value) ?? 0) + incr)))
            
        } else {
            
            fruitPad.set(value: String(max(0, (Int(fruitPad.value) ?? 0) + incr)))
        }
        
        load()
        
    }
    
    /// Estimates and returns `Level` for a given score value if `shouldPredictLevel` is true.
    private func getLevelFor(_ score: Int) -> Level {
        
        var levelNum = Int(fruitPad.value) ?? 0
        
        if shouldPredictLevel {
            
            switch score {
                    
                case 0...11150:         levelNum = cherry
                case 11151...23742:     levelNum = strawberry
                case 23743...38404:     levelNum = orange
                case 38405...42354:     levelNum = pretzel
                case 42355...51571:     levelNum = apple
                case 51572...66652:     levelNum = pear
                case 66653...81478:     levelNum = banana1
                case 81479...87994:     levelNum = banana2
                case 87995...93412:     levelNum = banana3
                case 93413...104802:    levelNum = banana4
                case 104803...105338:   levelNum = banana5
                case 105339...110950:   levelNum = banana6
                case 110951...118707:   levelNum = banana7
                    
                default:                levelNum = banana8
                    
            }
            
        }
        
        return Level.get(levelNum)
        
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
                      forID id: String) {
        
        // Disable prediction as soon as user has set level.
        // Don't fight the user.
        if id == fruitPad.id { shouldPredictLevel = false }
        
        load()
        
    }
    
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
    
    /// Called when user updates or adds a new `Score`
    ///
    /// - Parameters:
    /// - new:The new `Score` or an updated value.
    /// - replacing: The old value to be replaced with `new`
    func set(new: Score, replacing: Score?)
    
}
