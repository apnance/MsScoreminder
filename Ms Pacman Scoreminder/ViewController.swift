//
//  ViewController.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils

class ViewController: UIViewController {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var backgroundStripeView: UIView!
    @IBOutlet weak var highscoreView: UIView!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var highDateLabel: UILabel!
    @IBOutlet weak var highLevelIcon: UIImageView!
    @IBOutlet weak var scoreInput: UITextField!
    @IBOutlet weak var levelSelector: UISegmentedControl!
    @IBOutlet weak var totalMoneySpentLabel: UITextField!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var scoresView: UIView!
    
    @IBOutlet weak var roundView: RoundView!
    @IBOutlet weak var deleteContainerView: UIView!
    @IBOutlet weak var deleteScoreContainerView: UIView!
    
    @IBOutlet weak var deleteScoreLabel: UILabel!
    @IBAction func didTapDeleteScore(_ sender: UIButton) {
        
        showDeleteConfirmation(false)
        
        if sender.tag == 1 { delete(score: scoreToDelete) }
        
    }
    
    private var scoreToDelete: Score?
    private let (w, h, p) = (100.0, 50.0, 10.0)
    
    var scoreMan = ScoreManager()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        initData()
        
        initUI()
        
    }
    
    private func showDeleteConfirmation(_ shouldShow: Bool) {
        
        deleteContainerView.isHidden = !shouldShow
        
    }
    
    private func confirmDeletion(of score: Score) {
        
        let scoreView = AtomicScoreView.new(delegate: nil, withScore: score)
        
        deleteScoreContainerView.removeAllSubviews()
        deleteScoreContainerView.translatesAutoresizingMaskIntoConstraints = true
        deleteScoreContainerView.addSubview(scoreView)
        
        scoreView.center = deleteScoreContainerView.frame.center
        
        deleteContainerView.isHidden = false
        
    }
 
    
    func outlineLabel(_ label: UILabel) {
        
        let strokeTextAttributes = [
            NSAttributedString.Key.strokeColor : UIColor(named: "Banana")!,
            NSAttributedString.Key.foregroundColor : UIColor(named: "Pink")!,
            NSAttributedString.Key.font : label.font!,
            NSAttributedString.Key.strokeWidth : -3.5,

        ] as [NSAttributedString.Key : Any]
        
        label.attributedText = NSMutableAttributedString(string: label.attributedText?.string ?? label.text ?? "-?-", attributes: strokeTextAttributes)
        
    }
    
    private func delete(score: Score?) {
        
        guard let score = score
        else { return /*EXIT*/ }
        
        print("Deleting: \(score)")
        
        scoreMan.remove(score)
        archive()
        
        scoreToDelete = nil
        updateVolatileUI()
        
    }
    
    private func scoreUI() {
        
        scoresView.addDashedBorder(.white, width: 5, dashPattern: [0.1,12], lineCap: .round)
        
        let scores = scoreMan.getLast(18)
        let colCount = Int(scoresView.frame.width) / Int(w)
        var col = 1
        
        var (xO, yO) = ((scoresView.frame.width / colCount.double) / 2.0, (h + p) * 0.55)
        
        scoresView.removeAllSubviews()
        
        for score in scores {
            
            let scoreView = AtomicScoreView.new(delegate: self,
                                                withScore: score)
            
            scoreView.translatesAutoresizingMaskIntoConstraints = true
            scoresView.addSubview(scoreView)
            
            // Layout
            scoreView.center = CGPoint(x: xO, y: yO)
            
            col += 1
            
            if col > colCount {
                
                xO = (scoresView.frame.width / colCount.double) / 2.0
                col = 1
                
                yO += (h + p)
                
            } else {
                
                xO += scoresView.frame.width / colCount.double

            }
            
        }
        
    }
    
    private func addShadows() {
        
        let views = [scoresView!,
                     roundView!,
                     deleteScoreContainerView!,
                     deleteScoreLabel!]
        
        for view in views {
            
            view.layer.shadowColor   = UIColor.black.cgColor
            view.layer.shadowOffset  = CGSize(width: 5, height: 2)
            view.layer.shadowOpacity = Float(0.3)
            
        }
        
    }
    
    private func initData() { unarchive(resetArchive: Configs.resetArchive) }
    
    // TODO: Clean Up - factor out several sub-func from initUI()
    private func initUI() {
        
        outlineLabel(deleteScoreLabel)
        outlineLabel(highscoreLabel)
        
        showDeleteConfirmation(false)
        
        addShadows()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleMainBodyTap(sender:)))
        mainView.addGestureRecognizer(tap)
        
        backgroundStripeView.layer.cornerRadius = backgroundStripeView.frame.width * 0.47
        totalMoneySpentLabel.textColor = UIColor(named: "Banana")
        
        backgroundStripeView.layer.borderColor = UIColor(named: "Banana")?.cgColor
        backgroundStripeView.layer.borderWidth = backgroundStripeView.frame.width * 0.04
        scoreInput.layer.borderColor = UIColor.clear.cgColor
        
        let normalAtts = [NSAttributedString.Key.foregroundColor: backgroundStripeView.backgroundColor as Any]
        
        // level selector
        levelSelector.selectedSegmentTintColor = UIColor(named: "Blue")
        levelSelector.removeAllSegments()
        levelSelector.isEnabled = false
        levelSelector.alpha = 0
        
        levelSelector.setTitleTextAttributes(normalAtts, for: .normal)
        
        let selectedAtts = [NSAttributedString.Key.foregroundColor: UIColor.white as Any]
        levelSelector.setTitleTextAttributes(selectedAtts, for: .selected)
        
        for segment in 0..<Score.levelCount {
            
            levelSelector.insertSegment(with: Score.iconFor(level: segment),
                                        at: segment,
                                        animated: false)
            
        }
        
        scoreInput.addTarget(self, action: #selector(scoreDidChange(sender:)), for: .editingChanged)
        levelSelector.addTarget(self, action: #selector(selectLevel(sender:)), for: .valueChanged)
        
        updateVolatileUI()
        
    }
    
    @objc func handleMainBodyTap(sender: Any) {
        
        scoreInput.resignFirstResponder()
        
        // Hide
        showDeleteConfirmation(false)
        
    }
    
    @objc func selectLevel(sender: UISegmentedControl) {
        
        handleMainBodyTap(sender: self)
        
        let scoreText = scoreInput.text!
        
        guard !scoreText.isEmpty
        else {
            
            levelSelector.selectedSegmentIndex = UISegmentedControl.noSegment
            
            return /*EXIT*/
            
        }
        
        scoreMan.set(Score(date: Date(),
                           score: Int(scoreText)!,
                           level: levelSelector.selectedSegmentIndex))
        
        updateVolatileUI()
        
        archive()
        
    }
    
    @objc func scoreDidChange(sender: UITextField) {
        
        let score = Int(sender.text!) ?? -1
        
        // Disable levelSelector if score is not positive and evenly divisible by 5
        levelSelector.isEnabled = (score % 5) == 0
        
        levelSelector.alpha = !levelSelector.isEnabled ? 0 : 1
        
    }
    
    func updateVolatileUI() {
        
        DispatchQueue.main.async {
            
            self.highLevelIcon.rotateRandom(minAngle: 0, maxAngle: 5)
            
            if let high = self.scoreMan.getHighscore() {
                
                self.highscoreLabel.text         = high.displayScore
                self.highDateLabel.text          = high.date.simple
                
                self.highLevelIcon.image = UIImage(named: "ms_icon_\(high.level)")
                
                self.highscoreView.isHidden = false
                
                self.totalMoneySpentLabel.text = self.scoreMan.getMoneySpent()
                
                self.scoreUI()
                
            } else { self.highscoreView.isHidden = true }
            
        }
        
        
        
    }
    
    private func unarchive(resetArchive: Bool = false) {
        
        guard let archived: ScoreManager = CodableArchiver.unarchive(file: Configs.archiveKey,
                                                                     inSubDir: "")
        else {
            
            print("Unarchive failed to find archive, returning empty ScoreData")
            
            scoreMan = ScoreManager.importData()
            archive()
            
            return /*EXIT*/
            
        }
        
        scoreMan = archived
        
        if resetArchive {
            
            let suffix = "\(Configs.csvFile)_\(Date().description)"
            
            writeCSV(withSuffix: suffix)
            
            print("Unarchive bypassed. Resetting archive via data import.")
            print("Old data backed up to '/private/tmp/\(suffix)_v?.?.csv'")
            
            scoreMan = ScoreManager.importData()
            archive()
            
            return /*EXIT*/
            
        }
        
        print("Unarchive succeeded, returning archived ScoreData")
        
    }
    
    func archive() {
        
        CodableArchiver.archive(scoreMan,
                                toFile: Configs.archiveKey,
                                inSubDir: nil)
        
    }
    
    func writeCSV(withSuffix suffix: String) {
        
        let (scores, headers) = scoreMan.getScoreArray()
        
        Report.write(data: scores,
                     headers: headers,
                     fileSuffix: suffix,
                     versionOverride: nil)
        
        
    }
    
}

extension ViewController: AtomicScoreViewDelegate {
    
    func didTap(score: Score) {
        
        scoreToDelete = score
        confirmDeletion(of: score)
        
    }
    
    
}
