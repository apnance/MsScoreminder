//
//  ViewController.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils
import MessageUI

class ViewController: UIViewController {
    
    // MARK: - Properties
    var scoreMan = ScoreManager()
    private var scoreToDelete: Score?
    private let (w, h, p) = (100.0, 50.0, 10.0)
    
    // MARK: - Outlets
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var backgroundStripeView: UIView!
    @IBOutlet weak var highscoreView: UIView!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var highDateLabel: UILabel!
    @IBOutlet weak var highLevelIcon: UIImageView!
    @IBOutlet weak var scoreInput: UITextField!
    @IBOutlet weak var levelSelector: UISegmentedControl!
    @IBOutlet weak var totalMoneySpentLabel: UITextField!
    @IBOutlet weak var scoresContainerView: UIView!
    
    @IBOutlet weak var scoresView: UIView!
    @IBOutlet weak var scoresFilterLabel: UILabel!
    
    @IBOutlet weak var roundView: RoundView!
    @IBOutlet weak var deleteContainerView: UIView!
    @IBOutlet weak var deleteScoreContainerView: UIView!
    
    @IBOutlet weak var deleteScoreLabel: UILabel!
    
    // MARK: Actions
    @IBAction func didTapDeleteYesNoButton(_ sender: UIButton) {
        
        showDeleteConfirmation(false)
        
        if sender.tag == 1 { delete(score: scoreToDelete) }
        
    }
    
    @IBAction func didTapSend(_ sender: UIButton) {
        
        btnSendMail()
        
    }
    
    // MARK: - Overrides
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        scoreMan.open()
        
        uiInit()
        
    }
    
    override func viewDidAppear(_ animated: Bool) { scoreMan.warningsCheck() }
    override func viewWillDisappear(_ animated: Bool) { scoreMan.save() }
    
    // MARK: UI
    private func uiInit() {
        
        showDeleteConfirmation(false)

        uiMisc()
        uiBGStripe()
        uiScoreInput()
        uiLevelSelector()
        
        uiVolatile()
        
    }
    
    private func uiMisc() {
        
        outlineLabel(deleteScoreLabel)
        outlineLabel(highscoreLabel)
        addShadows()
        
        totalMoneySpentLabel.textColor = UIColor(named: "Banana")
        
        let dismissDeleteTap = UITapGestureRecognizer(target: self,
                                                      action: #selector(handleDismissDeleteUITap(sender:)))
        mainView.addGestureRecognizer(dismissDeleteTap)
        
        let cycleFilterTap = UITapGestureRecognizer(target: self,
                                                    action: #selector(cycleFilter))
        scoresContainerView.addGestureRecognizer(cycleFilterTap)
        
    }
    
    private func uiBGStripe() {
        
        let layer = backgroundStripeView.layer
        
        layer.cornerRadius = backgroundStripeView.frame.width * 0.47
        layer.borderColor = UIColor(named: "Banana")?.cgColor
        layer.borderWidth = backgroundStripeView.frame.width * 0.04
        
    }
    
    private func uiScoreInput() {
        
        scoreInput.layer.borderColor = UIColor.clear.cgColor
        scoreInput.addTarget(self,
                             action: #selector(scoreDidChange(sender:)),
                             for: .editingChanged)
        
    }
    
    private func uiLevelSelector() {
        
        let normalAtts = [NSAttributedString.Key.foregroundColor: backgroundStripeView.backgroundColor as Any]
        let selectedAtts = [NSAttributedString.Key.foregroundColor: UIColor.white as Any]
        
        levelSelector.selectedSegmentTintColor = UIColor(named: "Blue")
        levelSelector.removeAllSegments()
        levelSelector.isEnabled = false
        levelSelector.alpha     = 0
        levelSelector.setTitleTextAttributes(normalAtts, for: .normal)
        levelSelector.setTitleTextAttributes(selectedAtts, for: .selected)
        
        for segment in 0..<Score.levelCount {
            
            levelSelector.insertSegment(with: Score.iconFor(level: segment),
                                        at: segment,
                                        animated: false)
            
        }
        
        levelSelector.addTarget(self,
                                action: #selector(selectLevel(sender:)),
                                for: .valueChanged)
        
    }
    
    /// Updates UI affected by changes to data - called frequently in response to user interaction.
    private func uiVolatile() {
        
        DispatchQueue.main.async {
            
            self.highLevelIcon.rotateRandom(minAngle: 0, maxAngle: 5)
            
            if let high = self.scoreMan.getHighscore() {
                
                self.highscoreLabel.text         = high.displayScore
                self.highDateLabel.text          = high.date.simple
                
                self.highLevelIcon.image = UIImage(named: "ms_icon_\(high.level)")
                
                self.highscoreView.isHidden = false
                
                self.totalMoneySpentLabel.text = self.scoreMan.getMoneySpent()
                
                self.uiScore()
                
            } else { self.highscoreView.isHidden = true }
            
        }
        
    }
    
    /// Builds/rebuilds list of scores in response to changes in ScoreFilter
    private func uiScore() {
        
        scoresView.addDashedBorder(.white,
                                   width: 5,
                                   dashPattern: [0.1,12],
                                   lineCap: .round)
        
        let scores = scoreMan.filter(count: 18)
        scoresFilterLabel.text = scoreMan.getFilterLabel()
        
        let colCount = Int(scoresView.frame.width) / Int(w)
        var col = 1
        
        var (xO, yO) = ((scoresView.frame.width / colCount.double) / 2.0, (h + p) * 0.55)
        
        scoresView.removeAllSubviews()
        
        for score in scores {
            
            let scoreView = AtomicScoreView.new(delegate: self,
                                                withScore: score, andRank: scoreMan.getRank(score))
            
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
    
    private func outlineLabel(_ label: UILabel) {
        
        let strokeTextAttributes = [
            NSAttributedString.Key.strokeColor : UIColor(named: "Banana")!,
            NSAttributedString.Key.foregroundColor : UIColor(named: "Pink")!,
            NSAttributedString.Key.font : label.font!,
            NSAttributedString.Key.strokeWidth : -3.5,

        ] as [NSAttributedString.Key : Any]
        
        label.attributedText = NSMutableAttributedString(string: label.attributedText?.string ?? label.text ?? "-?-", attributes: strokeTextAttributes)
        
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
    
    // MARK: Score Updates
    @objc func selectLevel(sender: UISegmentedControl) {
        
        handleDismissDeleteUITap(sender: self)
        
        let scoreText = scoreInput.text!
        
        guard !scoreText.isEmpty
        else {
            
            levelSelector.selectedSegmentIndex = UISegmentedControl.noSegment
            
            return /*EXIT*/
            
        }
        
        scoreMan.set(Score(date: Date(),
                           score: Int(scoreText)!,
                           level: levelSelector.selectedSegmentIndex))
                
        uiVolatile()
        
    }
    
    @objc func scoreDidChange(sender: UITextField) {
        
        let score = Int(sender.text!) ?? -1
        
        // Disable levelSelector if score is not a multiple of 10
        levelSelector.isEnabled = (score % 10) == 0
        
        levelSelector.alpha = !levelSelector.isEnabled ? 0 : 1
        
    }
    
    @objc fileprivate func cycleFilter() {
        
        scoreMan.cylecFilter()
        uiScore()
        
    }
    
    // MARK: Deletion
    @objc func handleDismissDeleteUITap(sender: Any) {
        
        scoreInput.resignFirstResponder()
        
        showDeleteConfirmation(false) // Hide
        
    }
    
    private func showDeleteConfirmation(_ shouldShow: Bool) {
        
        scoreInput.resignFirstResponder()
        
        deleteContainerView.isHidden = !shouldShow
        
    }
    
    private func delete(score: Score?) {
        
        guard let score = score
        else { return /*EXIT*/ }
        
        scoreMan.remove(score)
        
        scoreToDelete = nil
        uiVolatile()
        
    }
    
}

// MARK: - Email Data
extension ViewController: MFMailComposeViewControllerDelegate {
    
    func btnSendMail() {
        
       if MFMailComposeViewController.canSendMail() {
           
          let mail = MFMailComposeViewController()
           
           mail.setToRecipients(["apnance@gmail.com"])
           mail.setSubject("Ms. Score : Save Data : \(Date().simple)")
           mail.setMessageBody(buildHTML(), isHTML: true)
           mail.mailComposeDelegate = self
           
           // Attachment
           if let data = scoreMan.getCSV().data(using: .utf8) {
               
               mail.addAttachmentData(data as Data,
                                      mimeType: "text/csv",
                                      fileName: "\(Configs.File.generateBackupFileName())")
               
           }
              
          present(mail, animated: true)
           
       } else {
           
           NSLog("Email cannot be sent")
           
       }
        
    }
    
    private func buildHTML() -> String {
        
        let levelReport = scoreMan.getLevelReport().replacingOccurrences(of: "\n",
                                                                         with: "<br/>")
        
        return  """
                <html>\
                <style>
                body { background-color: #F0317E; font-size: 14pt; color: #FEE732; font-weight: 900;}
                .date { color: #1082C8; }
                .report { font-size: 8pt; color: black; }
                </style>\
                <body><br/><center>
                   Score Data : <span class="date">\(Date().simple)</span>
                    <br/><br/><span class="report">\(levelReport)</span>
                </center></body>\
                </html>
                """
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
       if let _ = error { self.dismiss(animated: true, completion: nil) }
        
        switch result {
            
        case .cancelled: NSLog("Cancelled"); break
            
        case .sent: NSLog("Mail sent successfully"); break
            
        case .failed: NSLog("Sending mail failed"); break
            
        default: break
            
       }
        
       controller.dismiss(animated: true, completion: nil)
        
    }
    
}

// MARK: - AtomicScoreViewDelegate
extension ViewController: AtomicScoreViewDelegate {
    
    func didTap(score: Score) {
        
        scoreToDelete = score
        
        let scoreView = AtomicScoreView.new(delegate: nil,
                                            withScore: score,
                                            andRank: scoreMan.getRank(score))
        
        deleteScoreContainerView.removeAllSubviews()
        deleteScoreContainerView.translatesAutoresizingMaskIntoConstraints = true
        deleteScoreContainerView.addSubview(scoreView)
        
        scoreView.center = deleteScoreContainerView.frame.center
        
        showDeleteConfirmation(true)
        
    }
    
}
