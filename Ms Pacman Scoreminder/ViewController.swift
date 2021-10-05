//
//  ViewController.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils
import MessageUI

class ViewController: UIViewController {
    
    private var scoreToDelete: Score?
    private let (w, h, p) = (100.0, 50.0, 10.0)
    
    var scoreMan = ScoreManager()
    
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
    
    
    @IBAction func didTapDeleteScore(_ sender: UIButton) {
        
        showDeleteConfirmation(false)
        
        if sender.tag == 1 { delete(score: scoreToDelete) }
        
    }
    
    @IBAction func didTapSend(_ sender: UIButton) {
        
        btnSendMail()
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        initData()
        
        initUI()
          
    }

    override func viewWillDisappear(_ animated: Bool) { scoreMan.save() }
    
    private func outlineLabel(_ label: UILabel) {
        
        let strokeTextAttributes = [
            NSAttributedString.Key.strokeColor : UIColor(named: "Banana")!,
            NSAttributedString.Key.foregroundColor : UIColor(named: "Pink")!,
            NSAttributedString.Key.font : label.font!,
            NSAttributedString.Key.strokeWidth : -3.5,

        ] as [NSAttributedString.Key : Any]
        
        label.attributedText = NSMutableAttributedString(string: label.attributedText?.string ?? label.text ?? "-?-", attributes: strokeTextAttributes)
        
    }
    
    private func scoreUI() {
        
        scoresView.addDashedBorder(.white, width: 5, dashPattern: [0.1,12], lineCap: .round)
        
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
    
    private func initData() {
        
//        scoreMan.unarchive(resetArchive: Configs.resetArchive)
        scoreMan.open()
        
    }
    
    // TODO: Clean Up - factor out several sub-func from initUI()
    private func initUI() {
        
        outlineLabel(deleteScoreLabel)
        outlineLabel(highscoreLabel)
        
        showDeleteConfirmation(false)
        
        addShadows()
        
        let dismissDeleteTap = UITapGestureRecognizer(target: self, action: #selector(handleDismissDeleteUITap(sender:)))
        deleteContainerView.addGestureRecognizer(dismissDeleteTap)
        
        let cycleFilterTap = UITapGestureRecognizer(target: self, action: #selector(cycleFilter))
        scoresContainerView.addGestureRecognizer(cycleFilterTap)
        
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
    
    @objc func handleDismissDeleteUITap(sender: Any) {
        
        scoreInput.resignFirstResponder()
        
        // Hide
        showDeleteConfirmation(false)
        
    }
    
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
        
//        scoreMan.save()
        
        updateVolatileUI()
        
    }
    
    @objc func scoreDidChange(sender: UITextField) {
        
        let score = Int(sender.text!) ?? -1
        
        // Disable levelSelector if score is not positive and evenly divisible by 5
        levelSelector.isEnabled = (score % 5) == 0
        
        levelSelector.alpha = !levelSelector.isEnabled ? 0 : 1
        
    }
    
    private func showDeleteConfirmation(_ shouldShow: Bool) {
        
        deleteContainerView.isHidden = !shouldShow
        
    }
    
    @objc fileprivate func cycleFilter() {
        
        scoreMan.cylecFilter()
        scoreUI()
        
    }
    
    private func confirmDeletion(of score: Score) {
        
        let scoreView = AtomicScoreView.new(delegate: nil, withScore: score, andRank: scoreMan.getRank(score))
        
        deleteScoreContainerView.removeAllSubviews()
        deleteScoreContainerView.translatesAutoresizingMaskIntoConstraints = true
        deleteScoreContainerView.addSubview(scoreView)
        
        scoreView.center = deleteScoreContainerView.frame.center
        
        deleteContainerView.isHidden = false
        
    }
 
    private func delete(score: Score?) {
        
        guard let score = score
        else { return /*EXIT*/ }
        
        scoreMan.remove(score)
        
        scoreToDelete = nil
        updateVolatileUI()
        
    }
    
}

extension ViewController: AtomicScoreViewDelegate {
    
    func didTap(score: Score) {
        
        scoreToDelete = score
        confirmDeletion(of: score)
        
    }
    
}

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
                                      mimeType: "text/CSV",
                                      fileName: "Ms_Score_\(Date().simpleUnderScore).csv")
               
           }
              
          present(mail, animated: true)
           
       } else {
           
           NSLog("Email cannot be sent")
           
       }
        
    }
    
    private func buildHTML() -> String {
        
        let levelReport = scoreMan.getLevelReport().replacingOccurrences(of: "\n", with: "<br/>")
        
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
