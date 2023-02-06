//
//  DayWebView.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 2/1/23.
//

import UIKit
import WebKit

class DailySummaryWebView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet private weak var webView: WKWebView!
    
    var delegate: DayWebViewDelegate?
    
    private var date = Date()
    
    @IBAction func didPushLeftButton(_ sender: UIButton) { delegate?.didPushLButton(currentDate: date) }
    @IBAction func didPushRightButton(_ sender: UIButton) { delegate?.didPushRButton(currentDate: date)}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("DayWebView", owner: self, options: nil)
        contentView.constrainIn(self)
        
    }
    
    func load(html: String, forDate date: Date) {
        
        self.date = date
        webView.loadHTMLString(html, baseURL: nil)
        
    }
}

extension UIView {
    
    func constrainIn(_ container: UIView!) -> Void {
        
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        
        container.addSubview(self);
        
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        
    }
    
}

protocol DayWebViewDelegate {
    
    func didPushLButton(currentDate: Date)
    func didPushRButton(currentDate: Date)
    
}
