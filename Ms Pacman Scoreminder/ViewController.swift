//
//  ViewController.swift
//  Ms Pacman Scoreminder
//
//  Created by Aaron Nance on 9/21/21.
//

import MessageUI
import WebKit
import APNUtil
import APNGraph

class ViewController: UIViewController {
    
    // MARK: - Properties
    var statMan             = StatManager()
    private let (w, h, p)   = (117.0, 58.0, 3.5)
    private var scoreCycler = (num: -34,
                               incr: 1,
                               dataCurrent: 1,
                               dataMax: 0)
    
    private var scoreViews = [AtomicScoreView]()
    private var scoreEditor: ScoreEditor!
    private var timer: APNTimer?
    private var lastDailyRunDate = Date().simple
    
    /// Flag that triggers `uiVolatile()` call in `uiLoop()`
    private var volatileUIShouldUpdate = false
    
    
    // MARK: - Outlets
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var marqueeFG: UIImageView!
    @IBOutlet weak var marqueeMid: UIView!
    @IBOutlet weak var marqueeBG: UIImageView!
    @IBOutlet weak var backgroundStripeView: UIView!
    @IBOutlet weak var marqueeScoreView: UIView!
    @IBOutlet weak var marqueeScoreScoreLabel: UILabel!
    @IBOutlet weak var marqueeScoreTitleLabel: UILabel!
    @IBOutlet weak var marqueeScoreDateLabel: UILabel!
    @IBOutlet weak var marqueeLevelIcon: UIImageView!
    @IBOutlet weak var marqueeLevelIconContainerView: RoundView!
    @IBOutlet weak var totalMoneySpentLabel: UITextField!
    @IBOutlet weak var versionLabel: UITextField!
    @IBOutlet weak var scoresContainerView: UIView!
    @IBOutlet weak var scoresView: UIView!
    @IBOutlet weak var scoresFilterLabel: UILabel!
    @IBOutlet weak var scoreFilterControlsStackView: UIStackView!
    
    @IBOutlet weak var spritesViewContainer: RoundView!
    @IBOutlet weak var spriteViewGhost1:     UIImageView!
    @IBOutlet weak var spriteViewMSPacMan:   UIImageView!
    @IBOutlet weak var spriteViewPellets:    UIImageView!
    
    // Launch Screen Replica "Curtain"
    @IBOutlet weak var launchScreenReplicaCurtainView: UIView!
    @IBOutlet weak var launchScreenReplicaSplashTitleView: UIView!
    
    // Pop-Up
    @IBOutlet weak var popUpScreenView: UIView!
    
    // Filter
    @IBOutlet weak var dataSelector: UISegmentedControl!
    @IBOutlet weak var avgSorted: UISegmentedControl!
    @IBOutlet weak var dateSorted: UISegmentedControl!
    @IBOutlet weak var dailyHighlightsView: DailyHighlightsView!
    
    // Email
    @IBOutlet weak var tresButtonsStackView: UIStackView!
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
    
    // Graph
    @IBOutlet weak var graphContainerView: UIView!
    @IBOutlet weak var showGraphButton: RoundButton!
    @IBOutlet weak var graphImageView: UIImageView!
    @IBOutlet weak var graphTitleLabel: UILabel!
    @IBOutlet weak var graphPointCountSlider: UISlider!
    @IBOutlet weak var graphPointCountLabel: UILabel!
    @IBOutlet weak var graphPointSliderPacPelletView: UIView!
    
    // Day WebView
    @IBOutlet weak var dailySummaryWebView: DailySummaryWebView!
    
    // MARK: Actions
    @IBAction func didTapRangeFilterButton(_ sender: RoundButton) {
        
        switch sender.tag {
                
            case 0 : uiGraph(dateRange: .week)
                
            case 1 : uiGraph(dateRange: .month)
                
            case 2 : uiGraph(dateRange: .year)
                
            case 3 : uiGraph(dateRange: .all)
                
            default: fatalError()
        }
        
    }
    
    // Mail
    @IBAction func didTapSend(_ sender: UIButton) {
    
        btnSendMail()
        
    }
    
    // Graph
    @IBAction func didTapShowGraph(_ sender: UIButton) {
        
        htmlTestView.isHidden = true // Hide
        uiGraph()
        
    }
    
    @IBAction func didTapShowScoreEditor(_ sender: UIButton) {
        
        htmlTestView.isHidden = true // Hide
        scoreEditor.load(score: .zero)
        
    }
    
    /// Starts the process of updating slider UI, is high overhead and should only be called on touch down.
    @IBAction func beginChangingGraphPointSlider(_ sender: UISlider) { uiManagePointCount() }
    /// Updates point count label UI with low overhead and should be called continuously throughout the changing of the slider position.
    @IBAction func isChangingGraphPointSlider(_ sender: UISlider) { uiManagePointCount(refreshData: false) }
    /// Triggers a call to uiGraph and should only be called once at the end of the slider interaction during a touch up event.
    @IBAction func didChangeGraphPointSlider(_ sender: Any) { uiGraph() }
    
    
    // MARK: - Overrides
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let l22 = Level.get(22)
        let l5 = Level.get(5)
        
        // Dev Utility
        // print(StatManager.generateTestCSV(scoreCount: 20000))
        
        launchScreenReplicaCurtainView.isHidden = false
        
        scoreEditor = ScoreEditor(superView: view, delegate: self)
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            self.statMan.open(){ self.uiInit() }
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        statMan.warningsCheck()
        uiGraphSlider()
        
    }
    
    // MARK: UI
    private func uiInit() {
        
        volatileUIShouldUpdate = true
        
        DispatchQueue.main.async {
            
            self.uiMisc()
            self.uiBGStripe()
            self.uiBuildFilterSelectors()
            self.uiRotateMarquee()
            self.uiLoop()
            self.uiAnimateSprites()
            self.uiOpeningAnimation()
            
        }
        
    }
    
    
    /// Manages the syncing of `graphPointCountLabel` with `graphPointCountSlider`'s position.
    /// - Parameter refreshData: Flag triggering or suppressing the refreshing of statMan.filterAll() data.  Default is `true`
    /// - Parameter withDateRange: a DateRange enum specifying the range ot dates to return.
    /// - Returns: The count of filtered `Score`s currently selected.
    @discardableResult func uiManagePointCount(refreshData: Bool = true,
                                               withDateRange dateRange: DateRange = .unspecified) -> [Score] {
        
        let filtered = statMan.filterAll(refreshData: refreshData,
                                         dateRange: dateRange,
                                         percentOfCount: graphPointCountSlider.value.double)
        
        DispatchQueue.main.async {
            
            self.graphPointCountLabel.text = String(describing: filtered.count)
            
        }
        
        return filtered
        
    }
    
    /// Builds and displays a graph of all game scores
    func uiGraph(dateRange: DateRange = .unspecified) {
        
        DispatchQueue.main.async { [self] in
            
            let trimmedScores       = uiManagePointCount(withDateRange: dateRange)
            
            graphTitleLabel.text    = statMan.getFilterLabel(dateRange: dateRange)
            
            let graph               = APNGraph<Score>(points: trimmedScores)
            graph.attributes        = APNGraphAttributes(axisLineWidth: 0.2,
                                                         axisLineColor: .black,
                                                         axisSmallDimensionPercent: 0.4,
                                                         axisLabelFontName: "Futura", //"Futura-Bold"
                                                         axisLabelVerticalFontSize: 8,
                                                         axisLabelHorizontalFontSize: 6,
                                                         axisLabelFontColor: .red,
                                                         axisTitleVertical: "Average Score",
                                                         axisTitleHorizontal: "Date Played",
                                                         dotDiameter: 15,
                                                         dotOutlineColor: .black,
                                                         dotOutlineWidth: 0.4)
            
            self.graphImageView.layer.borderColor   =  Colors.banana.cgColor
            self.graphImageView.layer.borderWidth   = 1.5
            self.graphImageView.layer.cornerRadius  = 10
            
            self.graphImageView.backgroundColor     = UIColor.white
            
            graph.drawGraph(in: self.graphImageView, shouldAnimate: true)
            
            // Show
            showGraph(true)
            
        }
        
    }
    
    /// Initializes graphPointCountSlider UI
    /// - important: This method must be called after constraints are finalized(i.e. in viewDidAppear() or later).
    func uiGraphSlider() {
        
        graphPointCountSlider.setThumbImage(UIImage(named:"ms_icon_ms_pacman"), for: .normal)
        graphPointCountSlider.maximumTrackTintColor = .clear
        graphPointCountSlider.minimumTrackTintColor = Colors.pink
        
        graphPointSliderPacPelletView.addDashedLine(.white,
                                                    width: 3.5,
                                                    dashPattern: [0.1,12],
                                                    lineCap: .round,
                                                    isHorizontal: true)
        
    }
    
    /// A method that is called at repeating interval defined  in `Configs.UI.Timing.uiLoopInterval`
    ///
    /// - note: useful game-loop-like repeated UI updates.
    private func uiLoop() {
        
        if timer.isNil {
            
            timer = APNTimer(name: "scores",
                             repeatInterval: Configs.UI.Timing.Loop.interval) {
                
                _ in
                
                self.uiLoop()
                
            }
            
            return /*EXIT*/
            
        }
        
        // once-daily UI
        uiRepeatDaily()
        
        // scores
        uiScoreCycler()
        
        // general UI updates
        uiVolatile()
        
    }
    
    fileprivate func uiOpeningAnimation() {
        
        UIView.buildAnimation(withDuration: Configs.UI.Timing.Curtain.revealTime,
                              delay: Configs.UI.Timing.Curtain.revealDelayTime,
                              withFrames: [
                                (0.0, 10, { self.launchScreenReplicaSplashTitleView.alpha = 0.0 } ),    // Splash Title
                                (-2.0, 9, { self.launchScreenReplicaCurtainView.alpha = 0.0 } ),        // Curtain
                                (0.0, 7, { self.marqueeFG.alpha = 1.0 } ),                              // Marquee FG (Ms. Pac-Man)
                                (0.0, 5, { self.marqueeBG.alpha = 1.0 } ),                              // Margue BG (Ghosts)
                                (0.0, 4, { self.marqueeMid.alpha = 1.0 } ),                             // Margue Mid (Scores)
                                (0.0, 3, { self.streaksContainerView.alpha = 1.0} ),                    // Streaks
                                (0.0, 2, { self.dailyHighlightsView.alpha = 0.8 }),                     // Daily Summary
                                (0.0, 1.75, { self.spritesViewContainer.alpha  = 1.0} ),                // Sprites
                                (0.0, 1.5, { self.tresButtonsStackView.alpha = 1.0 }),                  // Add Score/Graph/Mail buttons
                                (0.0, 3.5, { // Scores
                                    self.scoresContainerView.alpha              = 1.0
                                    self.scoreFilterControlsStackView.alpha     = 1.0 })
                              ],
                              completionHandler: nil)
        
    }
    
    fileprivate func uiHideScore(_ shouldHide: Bool) {
        
        marqueeScoreScoreLabel.isHidden = shouldHide
        marqueeScoreTitleLabel.isHidden = shouldHide
        marqueeScoreDateLabel.isHidden  = shouldHide
        marqueeLevelIcon.isHidden       = shouldHide
        
    }
    
    fileprivate func uiRotateMarquee(phase: Int = -1,
                                     targetAlpha: Double = 1,
                                     delay: Double = 0.0) {
        
        DispatchQueue.main.async {
            
            var phase = phase  // do not modify phase outside of setUI()
            
            let phaseContent = [(title: "HIGH SCORE",
                                 score: self.statMan.getHighscore(),
                                 delay: Configs.UI.Timing.Marquee.highDelay),
                                (title: "AVERAGE SCORE",
                                 score: self.statMan.getAvgScore(),
                                 delay: Configs.UI.Timing.Marquee.avgDelay),
                                (title: "LOW SCORE",
                                 score: self.statMan.getLowscore(),
                                 delay: Configs.UI.Timing.Marquee.lowDelay)]
            
            func setUI() {
                
                if phase == -1 { self.uiHideScore(false) }
                
                phase = phase == phaseContent.lastUsableIndex ? 0 : phase + 1
                
                let content = phaseContent[phase]
                
                if let score = content.score {
                    
                    self.marqueeScoreScoreLabel.text    = score.displayScore
                    self.marqueeScoreTitleLabel.text    = content.title
                    self.marqueeScoreDateLabel.text     = score.date.simple
                    self.marqueeLevelIcon.image         = UIImage(named: "ms_icon_\(score.level.num)")
                    
                }
                
            }
            
            if phase == -1 { setUI() }
            
            UIView.animate(withDuration: Configs.UI.Timing.Marquee.fadeDuration,
                           delay: delay,
                           options: .allowAnimatedContent,
                           animations: {
                
                self.marqueeScoreScoreLabel.alpha   = targetAlpha
                self.marqueeLevelIcon.alpha         = targetAlpha
                self.marqueeScoreDateLabel.alpha    = targetAlpha
                self.marqueeScoreTitleLabel.alpha   = targetAlpha
                
            }) {
                
                (success: Bool)
                in
                
                if targetAlpha == 0 {   // Has faded, time to switch to next score type
                    
                    setUI()
                    
                    self.uiRotateMarquee(phase: phase,
                                         targetAlpha: 1,
                                         delay: 0.1)
                    
                } else {                // Fade out
                    
                    self.uiRotateMarquee(phase: phase,
                                         targetAlpha: 0,
                                         delay: phaseContent[phase].delay)
                    
                }
                
            }
            
        }
        
    }
    
    /// Code to be run once every new day.  Used to update stats such as streaks that should change with
    /// the changing of the day.
    fileprivate func uiRepeatDaily() {
        
        let currenDate = Date().simple
        
        if lastDailyRunDate != currenDate {
            
            lastDailyRunDate        = currenDate
            volatileUIShouldUpdate  = true
            
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
        
        // Delegates
        dailySummaryWebView.delegate = self
        
        // Hide Pop-Up Screen
        popUpScreenView.isHidden = true
        
        // Hide Score Initially
        uiHideScore(true)
        
        // Hide Streaks Initially
        streaksContainerView.alpha = 0
        
        // Version
        versionLabel.text = "v\(Bundle.appVersion)"
        
        // Outline
        Utils.UI.outlineLabel(marqueeScoreScoreLabel)
        
        // Shadow
        addShadows()
        
        mainView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                             action: #selector(dismissPopUpUI(sender:))))
        
        streaksContainerView.rotate(angle: Configs.UI.Rotations.streaksView)
        
    }
    
    /// Styles the large pink/yellow background stripe.
    private func uiBGStripe() {
        
        let layer = backgroundStripeView.layer
        
        layer.cornerRadius  = backgroundStripeView.frame.width * 0.47
        layer.borderColor   = Colors.banana.cgColor
        layer.borderWidth   = backgroundStripeView.frame.width * 0.04
        
    }
    
    private func uiBuildFilterSelectors() {
        
        let filter          = statMan.prefs.scoreSortFilter
        
        let normalAtts      =   [NSAttributedString.Key.font: UIFont(name: "Futura-Bold", size: 8) as Any,
                                 NSAttributedString.Key.foregroundColor: UIColor(named:"Banana") as Any]
        let selectedAtts    =   [NSAttributedString.Key.font: UIFont(name: "Futura-Bold", size: 8) as Any,
                                 NSAttributedString.Key.foregroundColor: UIColor.white as Any]
        
        dataSelector.selectedSegmentIndex = filter.type == .recents ? 0 : (filter.type == .highs ? 1 : 2 )
        
        dataSelector.addTarget(self,
                               action: #selector(filter(sender:)),
                               for: .valueChanged)
        
        dataSelector.selectedSegmentTintColor = Colors.blue
        
        dataSelector.setTitleTextAttributes(normalAtts, for: .normal)
        dataSelector.setTitleTextAttributes(selectedAtts, for: .selected)
        
        avgSorted.selectedSegmentIndex = filter.isAverage ? 0 : 1
        avgSorted.addTarget(self,
                            action: #selector(filter(sender:)),
                            for: .valueChanged)
        
        avgSorted.selectedSegmentTintColor = Colors.blue
        avgSorted.setTitleTextAttributes(normalAtts, for: .normal)
        avgSorted.setTitleTextAttributes(selectedAtts, for: .selected)
        
        dateSorted.selectedSegmentIndex = filter.isDateSorted ? 1 : 0
        dateSorted.addTarget(self,
                             action: #selector(filter(sender:)),
                             for: .valueChanged)
        
        dateSorted.selectedSegmentTintColor = Colors.blue
        dateSorted.setTitleTextAttributes(normalAtts, for: .normal)
        dateSorted.setTitleTextAttributes(selectedAtts, for: .selected)
        
        dateSorted.alpha = filter == .recents || filter == .avgRecents ? 0 : 1
        
    }
    
    /// Updates UI affected by changes to data - called repeatedly in `uiLoop`.
    ///
    /// - important: Do not call this method directly instead, to trigger a call,
    /// set `volatileUIShouldUpdate` to true.
    private func uiVolatile() {
        
        if !volatileUIShouldUpdate { return /*EXIT*/ }
        else { volatileUIShouldUpdate = false }
        
        DispatchQueue.main.async {
            
            self.statMan.tally()
            
            self.marqueeLevelIcon.rotateRandom(minAngle: 0, maxAngle: 5)
            
            self.dailyHighlightsView.load(self.statMan.getDailyStatsSummary())
            
            if self.statMan.getHighscore().isNotNil {
                
                self.marqueeScoreView.isHidden  = false
                
                self.totalMoneySpentLabel.text  = self.statMan.getMoneySpent()
                
            } else { self.marqueeScoreView.isHidden = true }
            
            if let streaks = self.statMan.getStreaks() {
                
                self.streakLongestCount.text = streaks.longest.length.description
                self.streakLongestDate1.text = streaks.longest.start?.simple ?? "-"
                self.streakLongestDate2.text = streaks.longest.end?.simple ?? "-"
                
                self.streakCurrentOrRecent.text = streaks.recent.isCurrent ? "CURRENT" : "RECENT"
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
        
        scoresContainerView.isHidden = false
        scoresFilterLabel.text = statMan.getFilterLabel(dateRange: .unspecified)
        
        let rowCount    = Int(scoresView.frame.height) / Int(h)
        let colCount    = Int(scoresView.frame.width) / Int(w)
        var col         = 1
        
        let scoreCount  = colCount * rowCount
        let scores      = statMan.filter(count: scoreCount)
        
        var (xO, yO)    = ((scoresView.frame.width / colCount.double) / 2.0, (h + p) * 0.55)
        
        // Remove old Score UI
        scoreViews      = []
        scoresView.removeAllSubviews()
        
        var currentDate = Date(timeIntervalSince1970: 0).simple
        var textColor   = Configs.UI.Display.defaultAtomicScoreViewTextColor
        
        for score in scores {
            
            if statMan.getFilter().isAverage {
                
                // Average - Only First Day is White
                textColor = score.date.isToday ? .white : Configs.UI.Display.defaultAtomicScoreViewTextColor
                
            } else if score.date.simple != currentDate {
                
                // Single - Alternate White/Banana
                currentDate = score.date.simple
                textColor   = textColor == .white ? Configs.UI.Display.defaultAtomicScoreViewTextColor : .white
                
            }
            
            let scoreView = AtomicScoreView.new(delegate: self,
                                                withScore: score,
                                                andData: statMan.getDisplayStats(score),
                                                textColor: textColor)
            
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
    
    /// Builds and runs Ms. Pac-Man/Ghost animation
    fileprivate func uiAnimateSprites() {
        
        let fruit       = AnimatedSprite.Fruit.self
        let ghost       = AnimatedSprite.Ghost.random()
        let ms          = AnimatedSprite.Ms.self
        
        let dotsImages  = AnimatedSprite.Pellets.movingLeft
        let ghostImages = ghost.lookClockWise
                            + ghost.lookCounterWise
                            + ghost.scared
                            + ghost.scared
                            + ghost.scared
                            + ghost.scaredFading
                            + ghost.scaredFading
                            + ghost.scaredFading
                            + ghost.scaredFading
                            + ghost.eyesUp
                            + ghost.eyesRight
                            + ghost.eyesDown
                            + ghost.eyesLeft
                            + ghost.eyesLeft
                            + ghost.eyesDown
                            + ghost.eyesRight
                            + ghost.eyesUp
                            + ghost.eyesUp
                            + ghost.eyesUp
                            + fruit.cherry.bounce
                            + fruit.strawberry.bounce
                            + fruit.orange.bounce
                            + fruit.pretzel.bounce
                            + fruit.apple.bounce
                            + fruit.pear.bounce
                            + fruit.banana.bounce
        
        let msImages    = ms.goRight
        
        let (rep,fps) = (0, 8.0)
        dotsImages.animate(in:  spriteViewPellets,  withRepeatCount: rep, fps: 14)
        msImages.animate(in:    spriteViewMSPacMan, withRepeatCount: rep, fps: fps)
        ghostImages.animate(in: spriteViewGhost1,   withRepeatCount: rep, fps: fps)
        
    }
    
    /// Adds drop shadows to all elements contained in internal views array
    private func addShadows() {
        
        Utils.UI.addShadows(to: [scoresView,
                                 streaksContainerView,
                                 dailyHighlightsView,
                                 scoresView,
                                 marqueeLevelIconContainerView,
                                 marqueeLevelIcon])
        
        Utils.UI.addShadows(to: [marqueeFG,
                                 marqueeBG,
                                 marqueeScoreTitleLabel],
                            withOpacity: 0.6)
        
    }
    
    @objc func filter(sender: UISegmentedControl) {
        
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
        
        // Don't re-graph if graph isn't visible
        if !graphContainerView.isHidden { uiGraph() }
        
    }
    
    // MARK: Deletion
    @objc func dismissPopUpUI(sender: Any) {
        
        // Hide
        showGraph(false)
        
        showDailySummary(false)
        
        htmlTestView.isHidden       = true
        popUpScreenView.isHidden    = true
        
        
    }
    
    func showGraph(_ shouldShow: Bool) {
        
        graphContainerView.isHidden = !shouldShow
        popUpScreenView.isHidden    = !shouldShow
        
    }
    
    func showDailySummary(_ shouldShow: Bool,
                          forDate date: Date? = nil) {
        
        dailySummaryWebView.isHidden         = !shouldShow
        popUpScreenView.isHidden    = !shouldShow
        
        if let date = date,
           shouldShow {
            
            statMan.tally()
            
            let html            = EmailManager.buildSummaryHTML(using: statMan,
                                                                forDate: date,
                                                                andDestination: .app)
            
            dailySummaryWebView.load(html: html, forDate: date)
            
        }
        
    }
    
}

// MARK: - DayViewDelegate
extension ViewController: DayWebViewDelegate {
    
    func didPushLButton(currentDate: Date) {
        
        if let closestPastScore  = statMan.getNearestPastAveragedScore(from: currentDate),
           closestPastScore.averagedGameCount > 0 {
            
            let date = closestPastScore.date
            let html            = EmailManager.buildSummaryHTML(using: statMan,
                                                                forDate: date,
                                                                andDestination: .app)
            dailySummaryWebView.load(html: html, forDate: date)
            
        }
        
    }
    
    func didPushRButton(currentDate: Date) {
        
        if let closestFutureScore  = statMan.getNearestFutureAveragedScore(from: currentDate),
           closestFutureScore.averagedGameCount > 1 {
            
            let date = closestFutureScore.date
            
            let html            = EmailManager.buildSummaryHTML(using: statMan,
                                                                forDate: date,
                                                                andDestination: .app)
            dailySummaryWebView.load(html: html, forDate: date)
            
        }
        
    }
    
}

// MARK: - MFMailComposeViewControllerDelegate
extension ViewController: MFMailComposeViewControllerDelegate {
    
    func btnSendMail() {
        
        if MFMailComposeViewController.canSendMail() {
            
            let mail = MFMailComposeViewController()
            
            mail.setToRecipients(["apnance@gmail.com"])
            mail.setSubject("Ms. Score : Save Data : \(Date().simple)")
            mail.setMessageBody(EmailManager.buildSummaryHTML(using: statMan,
                                                              forDate: Date(),
                                                              andDestination: .email),
                                isHTML: true)
            mail.mailComposeDelegate = self
            
            // Attachment
            if let data = statMan.csv.data(using: .utf8) {
                
                mail.addAttachmentData(data as Data,
                                       mimeType: "text/csv",
                                       fileName: "\(Configs.File.Path.generateBackupFileName())")
                
            }
            
            present(mail, animated: true)
            
        } else {
            
            APNUtil.Utils.log("Email cannot be sent")
            
            // toggle html test view
            htmlTestView.isHidden = !htmlTestView.isHidden
            
            if !htmlTestView.isHidden {
                
                // Simulate data access of sending email
                let _ = statMan.csv.data(using: .utf8)
                
                htmlTestView.loadHTMLString(EmailManager.buildSummaryHTML(using: statMan,
                                                                          forDate: Date(),
                                                                          andDestination: .email),
                                            baseURL: nil)
                
            }
            
        }
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
        if let _ = error { self.dismiss(animated: true, completion: nil) }
        
        switch result {
                
            case .cancelled: APNUtil.Utils.log("Cancelled"); break
                
            case .sent: APNUtil.Utils.log("Mail sent successfully"); break
                
            case .failed: APNUtil.Utils.log("Sending mail failed"); break
                
            default: break
                
        }
        
        controller.dismiss(animated: true, completion: nil)
        
    }
    
}

// MARK: - AtomicScoreViewDelegate
extension ViewController: AtomicScoreViewDelegate {
    
    func didTapSingle(score: Score) {
        
        scoreEditor.load(score: score, isDeletable: true)
        
    }
    
    func didTapAverage(score: Score) {
        
        self.showDailySummary(true, forDate: score.date)
        
    }
    
}

// - MARK: ScoreEditorDelegate
extension ViewController: ScoreEditorDelegate {
    
    func cleanUp() {
        
        DispatchQueue.global(qos: .default).async {
            
            self.statMan.save()
            self.volatileUIShouldUpdate = true
            
        }
        
    }
    
    func delete(score: Score) {
        
        statMan.delete(score, shouldSave: true)
        
    }
    
    /// Sets `new` Score and deletes `replacing` if not `nil`.
    func set(new: Score,
             replacing old: Score?) {
        
        if let old = old { statMan.delete(old) }
        
        if new.score % 10 == 0 {
            
            statMan.set(new)
            
            NotificationManager.shared.tomorrow(withTitle:      Configs.Notifications.title,
                                                andBody:        Configs.Notifications.body,
                                                notificationID: Configs.Notifications.id,
                                                hour:           Configs.Notifications.Time.hour,
                                                minute:         Configs.Notifications.Time.minute,
                                                second:         Configs.Notifications.Time.second,
                                                badgeNumber:    Configs.Notifications.badgeNumber,
                                                testMode:       Configs.Notifications.testMode)
            
        } else {
            
            assert(false,
                    """
                    Handle message user that they can't save scores that are not
                    multiples of 10 or better yet don't allow them to attempt to
                    save if not multiple of 10
                    """)
            
        }
        
    }
    
    
}
