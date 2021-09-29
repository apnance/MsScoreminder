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
    
    @IBOutlet weak var deleteContainerView: UIView!
    @IBOutlet weak var deleteScoreContainerView: UIView!
    
    @IBAction func didTapDeleteScore(_ sender: UIButton) {
        
        hideDelete()
        
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
    
    
    private func hideDelete() {
        
        deleteContainerView.isHidden = true
        
    }
    
    private func confirmDeletion(of score: Score) {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "AtomicScoreView", bundle: bundle)
        let scoreView = nib.instantiate(withOwner: self, options: nil).first as! AtomicScoreView
        scoreView.load(score: score)
        
        deleteScoreContainerView.removeAllSubviews()
        deleteScoreContainerView.addSubview(scoreView)
        
        scoreView.centerXAnchor.constraint(equalTo: deleteScoreContainerView.centerXAnchor).isActive = true
        scoreView.centerYAnchor.constraint(equalTo: deleteScoreContainerView.centerYAnchor).isActive = true
        
        scoreView.heightAnchor.constraint(equalToConstant: h).isActive = true
        scoreView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        scoreView.setNeedsLayout()
        
        deleteContainerView.isHidden = false
        
        
    }
    
    private func delete(score: Score?) {
        
        guard let score = score
        else { return /*EXIT*/ }
        
        print("Deleting: \(score)")
        
        //
        //        scoreInput.text = score.score.description
        scoreMan.remove(score)
        archive()
        //        levelSelector.selectedSegmentIndex = score.level
        //        scoreDidChange(sender: scoreInput)
        //
        scoreToDelete = nil
        updateVolatileUI()
        
        
        
    }
    
    private func scoreUI() {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "AtomicScoreView", bundle: bundle)
        
        let scores = scoreMan.getLast(10)
        
        var scoreCount = 0
        let rowCount = Int(scoresView.frame.width) / Int(w)
        
        var row = 1
        
        scoresView.removeAllSubviews()
        
        for score in scores {
            
            let scoreView = nib.instantiate(withOwner: self, options: nil).first as! AtomicScoreView
            
            scoreView.load(score: score)
            scoreView.translatesAutoresizingMaskIntoConstraints = false
            scoresView.addSubview(scoreView)
            
            scoreView.delegate = self
            //            scoreView.borderView.layer.borderColor = score.levelColor.cgColor
            
            scoreView.heightAnchor.constraint(equalToConstant: h).isActive = true
            scoreView.widthAnchor.constraint(equalToConstant: w).isActive = true
            
            let xO = (scoresView.frame.width / (rowCount.double + 1)) * row.double
            let yO = (h + p) * (scoreCount / rowCount).double
            
            
            scoreView.centerXAnchor.constraint(equalTo: scoresView.leadingAnchor, constant: xO).isActive = true
            scoreView.topAnchor.constraint(equalTo: scoresView.topAnchor, constant: yO).isActive = true
            scoreCount += 1
            row += 1
            row = row > rowCount ? 1 : row
            
        }
        
    }
    
    private func initData() { unarchive(resetArchive: Configs.resetArchive) }
    
    // TODO: Clean Up - factor out several sub-func from initUI()
    private func initUI() {
        
        hideDelete()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:)))
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
        
        for segment in 0..<Score.levels.count {
            
            levelSelector.insertSegment(withTitle: Score.levels[segment], at: segment, animated: false)
            
            levelSelector.setImage(UIImage(named: "ms_icon_\(segment)"), forSegmentAt: segment)
            
            
        }
        
        scoreInput.addTarget(self, action: #selector(scoreDidChange(sender:)), for: .editingChanged)
        levelSelector.addTarget(self, action: #selector(selectLevel(sender:)), for: .valueChanged)
        
        updateVolatileUI()
        
    }
    
    @objc func dismissKeyboard(sender: Any) { scoreInput.resignFirstResponder() }
    
    @objc func selectLevel(sender: UISegmentedControl) {
        
        dismissKeyboard(sender: self)
        
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
