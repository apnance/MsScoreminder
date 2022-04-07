//
//  ViewController.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import APNUtils
import MessageUI
import WebKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    var statMan = StatManager()
    private var scoreToDelete: Score?
    private let (w, h, p) = (100.0, 50.0, 10.0)
    
    
    private var scoreCycler  = (num: -34,
                                incr: 1,
                                dataCurrent: 1,
                                dataMax: 0)
    
    private var scoreViews = [AtomicScoreView]()
    private var timer: APNTimer?
    private var lastDailyRunDate = Date().simple
    
    
    // MARK: - Outlets
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var backgroundStripeView: UIView!
    @IBOutlet weak var highscoreView: UIView!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var highDateLabel: UILabel!
    @IBOutlet weak var highLevelIcon: UIImageView!
    @IBOutlet weak var highLevelIconContainerView: RoundView!
    @IBOutlet weak var scoreInput: UITextField!
    @IBOutlet weak var levelSelector: UISegmentedControl!
    @IBOutlet weak var totalMoneySpentLabel: UITextField!
    @IBOutlet weak var versionLabel: UITextField!
    @IBOutlet weak var scoresContainerView: UIView!
    
    @IBOutlet weak var scoresView: UIView!
    @IBOutlet weak var scoresFilterLabel: UILabel!
    
    // filter UI
    @IBOutlet weak var dataSelector: UISegmentedControl!
    @IBOutlet weak var avgSorted: UISegmentedControl!
    @IBOutlet weak var dateSorted: UISegmentedControl!
    
    @IBOutlet weak var dailySummaryView: DailySummaryView!
    
    @IBOutlet weak var roundView: RoundView!
    @IBOutlet weak var deleteContainerView: UIView!
    @IBOutlet weak var deleteScoreContainerView: UIView!
    
    @IBOutlet weak var deleteScoreLabel: UILabel!
    
    @IBOutlet weak var emailButton: RoundButton!
    @IBOutlet weak var htmlTestView: WKWebView!
    
    // Streaks
    @IBOutlet weak var streaksContainerView: RoundView!
    @IBOutlet weak var streakLongestCount: UILabel!
    @IBOutlet weak var streakLongestDate1: UILabel!
    @IBOutlet weak var streakLongestDate2: UILabel!
    @IBOutlet weak var streakCurrentOrRecent: UILabel!
    @IBOutlet weak var streakCurrentCount: UILabel!
    @IBOutlet weak var streakCurrentDate1: UILabel!
    @IBOutlet weak var streakCurrentDate2: UILabel!
    
    
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
        
        statMan.open()
        uiInit()
        
    }
    
    override func viewDidAppear(_ animated: Bool) { statMan.warningsCheck() }
    
    override func viewWillDisappear(_ animated: Bool) { statMan.save() }
    
    // MARK: UI
    private func uiInit() {
        
        showDeleteConfirmation(false)
        
        uiMisc()
        uiBGStripe()
        uiScoreInput()
        uiBuildLevelSelector()
        uiBuildFilterSelectors()
        uiVolatile()
        uiLoop()
        
    }
    
    /// A method that is called at repeating interval defined  in `Configs.UI.Timing.uiLoopInterval`
    ///
    /// - note: useful game-loop-like repeated UI updates.
    private func uiLoop() {
        
        if timer == nil {
            
            timer = APNTimer(name: "scores",
                             repeatInterval: Configs.UI.Timing.uiLoopInterval) {
                
                _ in
                
                self.uiLoop()
                
            }
            
            return /*EXIT*/
            
        }
        
        // daily UI
        uiRepeatDaily()
        
        // scores
        uiScoreCycler()
        
    }
    
    /// Code to be run once every new day.  Used to update stats such as streaks that should change with
    /// the changing of the day.
    fileprivate func uiRepeatDaily() {
        
        let currenDate = Date().simple
        
        if lastDailyRunDate != currenDate {
            
            lastDailyRunDate = currenDate
            uiVolatile()
            
        }
        
    }
    
    /// Cycles through updating `AtomicScoreViews`
    fileprivate func uiScoreCycler() {
        // cycle scores
        scoreCycler.dataMax = statMan.getStatCount() - 1
        
        if scoreCycler.num > 34 {
            
            scoreCycler.incr        = -1
            scoreCycler.dataCurrent = scoreCycler.dataCurrent >= scoreCycler.dataMax ? 0 : scoreCycler.dataCurrent + 1
            
        } else if scoreCycler.num < -16 {
            
            scoreCycler.incr        = 1
            scoreCycler.dataCurrent = scoreCycler.dataCurrent >= scoreCycler.dataMax ? 0 : scoreCycler.dataCurrent + 1
            
        } else if scoreCycler.num >= 0 && scoreCycler.num <= scoreViews.lastUsableIndex {
            
            scoreViews[scoreCycler.num].updateDisplay(useData: scoreCycler.dataCurrent)
            
        }
        
        scoreCycler.num += scoreCycler.incr
        
    }
    
    private func uiMisc() {
        
        // hide streaks initially
        streaksContainerView.alpha = 0
        
        // version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-?-"
        versionLabel.text = "v\(appVersion)"
        
        outlineLabel(deleteScoreLabel)
        outlineLabel(highscoreLabel)
        addShadows()
                
        let dismissPopUpUITap = UITapGestureRecognizer(target: self,
                                                       action: #selector(dismissPopUpUI(sender:)))
        mainView.addGestureRecognizer(dismissPopUpUITap)
        
        streaksContainerView.rotate(angle: Configs.UI.Rotations.streaksView)
        
    }
    
    /// Styles the large pink/yellow background stripe.
    private func uiBGStripe() {
        
        let layer = backgroundStripeView.layer
        
        layer.cornerRadius = backgroundStripeView.frame.width * 0.47
        layer.borderColor = UIColor(named: "Banana")?.cgColor
        layer.borderWidth = backgroundStripeView.frame.width * 0.04
        
    }
    
    /// Initializes scoreInput
    private func uiScoreInput() {
        
        scoreInput.delegate = self
        scoreInput.layer.borderColor = UIColor.clear.cgColor
        scoreInput.addTarget(self,
                             action: #selector(scoreDidChange),
                             for: .editingChanged)
        
    }
    
    /// Styles levelSelector
    private func uiBuildLevelSelector() {
        
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
    
    private func uiBuildFilterSelectors() {
        
        let filter = statMan.prefs.scoreSortFilter
        
        let normalAtts      =  [NSAttributedString.Key.font: UIFont(name: "Futura-Bold", size: 8) as Any,
                                NSAttributedString.Key.foregroundColor: UIColor(named:"Banana") as Any]
        let selectedAtts    = [NSAttributedString.Key.font: UIFont(name: "Futura-Bold", size: 8) as Any,
                               NSAttributedString.Key.foregroundColor: UIColor.white as Any]
        
        dataSelector.selectedSegmentIndex = filter.type == .recents ? 0 : (filter.type == .highs ? 1 : 2 )
        
        dataSelector.addTarget(self,
                               action: #selector(filter(sender:)),
                               for: .valueChanged)
        
        dataSelector.selectedSegmentTintColor = UIColor(named: "Blue")
        
        dataSelector.setTitleTextAttributes(normalAtts, for: .normal)
        dataSelector.setTitleTextAttributes(selectedAtts, for: .selected)
        
        avgSorted.selectedSegmentIndex = filter.isAverage ? 0 : 1
        avgSorted.addTarget(self,
                            action: #selector(filter(sender:)),
                            for: .valueChanged)
        
        avgSorted.selectedSegmentTintColor = UIColor(named: "Blue")
        avgSorted.setTitleTextAttributes(normalAtts, for: .normal)
        avgSorted.setTitleTextAttributes(selectedAtts, for: .selected)
        
        dateSorted.selectedSegmentIndex = filter.isDateSorted ? 1 : 0
        dateSorted.addTarget(self,
                             action: #selector(filter(sender:)),
                             for: .valueChanged)
        
        dateSorted.selectedSegmentTintColor = UIColor(named: "Blue")
        dateSorted.setTitleTextAttributes(normalAtts, for: .normal)
        dateSorted.setTitleTextAttributes(selectedAtts, for: .selected)
        
        dateSorted.alpha = filter == .recents || filter == .avgRecents ? 0 : 1
        
    }
    
    /// Updates UI affected by changes to data - called frequently in response to user interaction.
    private func uiVolatile() {
        
        DispatchQueue.main.async {
            
            self.statMan.tally()
            
            self.highLevelIcon.rotateRandom(minAngle: 0, maxAngle: 5)
            
            self.dailySummaryView.load(self.statMan.getDailyStatsSummary())
            
            if let high = self.statMan.getHighscore() {
                
                self.highscoreLabel.text         = high.displayScore
                self.highDateLabel.text          = high.date.simple
                
                self.highLevelIcon.image = UIImage(named: "ms_icon_\(high.level)")
                
                self.highscoreView.isHidden     = false
                
                self.totalMoneySpentLabel.text  = self.statMan.getMoneySpent()
                
            } else { self.highscoreView.isHidden = true }
            
            
            if let streaks = self.statMan.getStreaks() {
                
                if self.streaksContainerView.alpha == 0 {
                    UIView.animate(withDuration: Configs.UI.Timing.roundUIFadeTime) {
                        
                        self.streaksContainerView.alpha = 1.0
                        
                    }
                }
                
                self.streakLongestCount.text = streaks.longest.length.description
                self.streakLongestDate1.text = streaks.longest.start?.simple ?? "-"
                self.streakLongestDate2.text = streaks.longest.end?.simple ?? "-"
                
                self.streakCurrentOrRecent.text = streaks.recent.isCurrent ? "Current" : "Recent"
                self.streakCurrentCount.text = streaks.recent.length.description
                self.streakCurrentDate1.text = streaks.recent.start?.simple ?? Date.now.simple
                self.streakCurrentDate2.text = streaks.recent.end?.simple ?? Date.now.simple
                
            }
            
            self.uiScore()
            
        }
        
    }
    
    /// Builds/rebuilds list of scores in response to changes in ScoreFilter
    private func uiScore() {
        
        scoresView.addDashedBorder(.white,
                                   width: 5,
                                   dashPattern: [0.1,12],
                                   lineCap: .round)
        
        let scores = statMan.filter(count: 18)
        scoresFilterLabel.text = statMan.getFilterLabel()
        
        let colCount = Int(scoresView.frame.width) / Int(w)
        var col = 1
        
        var (xO, yO) = ((scoresView.frame.width / colCount.double) / 2.0, (h + p) * 0.55)
        
        scoreViews = []
        scoresView.removeAllSubviews()
        scoreViews = []
        
        for score in scores {
            
            let scoreView = AtomicScoreView.new(delegate: self,
                                                withScore: score,
                                                andData: statMan.getDisplayStats(score))
            
            scoreViews.append(scoreView)
            
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
    
    /// Styles `label` with pink text outlined in yellow border
    private func outlineLabel(_ label: UILabel) {
        
        let strokeTextAttributes = [
            NSAttributedString.Key.strokeColor : UIColor(named: "Banana")!,
            NSAttributedString.Key.foregroundColor : UIColor(named: "Pink")!,
            NSAttributedString.Key.font : label.font!,
            NSAttributedString.Key.strokeWidth : -3.5,
            
        ] as [NSAttributedString.Key : Any]
        
        label.attributedText = NSMutableAttributedString(string: label.attributedText?.string ?? label.text ?? "-?-", attributes: strokeTextAttributes)
        
    }
    
    /// Adds drop shadows to all elements contained in internal views array
    private func addShadows() {
        
        Utils.UI.addShadows(to: [scoresView,
                                 streaksContainerView,
                                 dailySummaryView,
                                 roundView,
                                 deleteScoreContainerView,
                                 deleteScoreLabel,
                                 scoresView,
                                 highLevelIconContainerView,
                                 highLevelIcon])
        
    }
    
    // MARK: Score Updates
    
    /// Handles user taps on levelSelector
    @objc func selectLevel(sender: UISegmentedControl) {
        
        dismissPopUpUI(sender: self)
        
        let scoreText = scoreInput.text!
        
        guard !scoreText.isEmpty
        else {
            
            levelSelector.selectedSegmentIndex = UISegmentedControl.noSegment
            
            return /*EXIT*/
            
        }
        
        statMan.set(Score(date: Date(),
                           score: Int(scoreText)!,
                           level: levelSelector.selectedSegmentIndex))
                
        uiVolatile()
        
    }
    
    @objc func filter(sender: UISegmentedControl) {
        
        dismissPopUpUI(sender: self)

        var filterType = ScoreSortFilter.FilterType.recents
        
        switch dataSelector.selectedSegmentIndex {
                
            case 1: filterType = .highs
                
            case 2: filterType = .lows
                
            default: filterType = .recents
                
        }
        
        let showDailies = avgSorted.selectedSegmentIndex == 0 ? true : false
        let dateSort = dateSorted.selectedSegmentIndex == 0 ? false : true
        
        dateSorted.alpha = filterType == .recents ? 0 : 1
        
        statMan.setFilter(filterType, daily: showDailies, dateSorted: dateSort)
        
        uiScore()
        
    }
    
    /// Handles changes to scoreInput
    @objc func scoreDidChange() {
        
        let score = Int(scoreInput.text!) ?? -1
        
        // Disable levelSelector if score is not a multiple of 10
        levelSelector.isEnabled = (score % 10) == 0
        
        levelSelector.alpha = !levelSelector.isEnabled ? 0 : 1
        
    }
    
    // MARK: Deletion
    @objc func dismissPopUpUI(sender: Any) {
        
        scoreInput.resignFirstResponder()
        
        // Hide
        showDeleteConfirmation(false)
        htmlTestView.isHidden = true
        
    }
    
    private func showDeleteConfirmation(_ shouldShow: Bool) {
        
        scoreInput.resignFirstResponder()
        
        deleteContainerView.isHidden = !shouldShow
        
    }
    
    private func delete(score: Score?) {
        
        guard let score = score
        else { return /*EXIT*/ }
        
        statMan.delete(score)
        
        scoreToDelete = nil
        uiVolatile()
        
    }
    
}

// MARK: - Email Data
extension ViewController: MFMailComposeViewControllerDelegate {
    
    func btnSendMail() {
        
        scoreInput.resignFirstResponder()
        
       if MFMailComposeViewController.canSendMail() {
           
           let mail = MFMailComposeViewController()
           
           mail.setToRecipients(["apnance@gmail.com"])
           mail.setSubject("Ms. Score : Save Data : \(Date().simple)")
           mail.setMessageBody(EmailManager.buildSummaryHTML(using: statMan),
                               isHTML: true)
           mail.mailComposeDelegate = self
           
           // Attachment
           if let data = statMan.getCSV().data(using: .utf8) {
               
               mail.addAttachmentData(data as Data,
                                      mimeType: "text/csv",
                                      fileName: "\(Configs.File.Path.generateBackupFileName())")
               
           }
              
          present(mail, animated: true)
           
       } else {
           
           NSLog("Email cannot be sent")
           
           // toggle html test view
           htmlTestView.isHidden = !htmlTestView.isHidden
           
           if !htmlTestView.isHidden {
               
               htmlTestView.loadHTMLString(EmailManager.buildSummaryHTML(using: statMan),
                                           baseURL: nil)
               
           }
           
       }
        
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
                                            andData: statMan.getDisplayStats(score))
        
        deleteScoreContainerView.removeAllSubviews()
        deleteScoreContainerView.translatesAutoresizingMaskIntoConstraints = true
        deleteScoreContainerView.addSubview(scoreView)
        
        scoreView.center = deleteScoreContainerView.frame.center
        
        showDeleteConfirmation(true)
        
    }
    
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    
        htmlTestView.isHidden = true // Hide
        
    }
    
}
