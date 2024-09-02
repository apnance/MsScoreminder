//
//  PlayReminder.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 9/2/24.
//

import APNUtil

/// A Scoreminder Daily Play Nag
struct PlayReminder {
    
    static func set(_ currentStreaklength: Int) {
        
        let notificationStartHours = Configs.Notifications.times
        
        for i in 0..<notificationStartHours.count {
            
            let body    = generateBody(currentStreaklength)
            let hour    = notificationStartHours[i]
            let id      = "\(Configs.Notifications.id)_\(hour)"
            let min     = Int.random(min: 1, max: 10)
            let sec     = 15
            
            // Cancel Existing
            NotificationManager.shared.cancel(id)
            
            // Set New
            NotificationManager.shared.tomorrow(withTitle:      Configs.Notifications.title,
                                                andBody:        body,
                                                notificationID: id,
                                                hour:           hour,
                                                minute:         min,
                                                second:         sec,
                                                badgeNumber:    currentStreaklength,
                                                testMode:       Configs.Notifications.testMode)
        }
        
    }
    
    private static func generateBody(_ streakLen: Int) -> String {
        
        if streakLen == 1 {
            
            return "Your daily game streak is in jeopardy!"
            
        } else {
            
            var scare = ""
            switch Int.random(min: 0, max: 3) {
                    
                case 0: scare   = "needs attention!"
                case 1: scare   = "hangs in the balance!"
                case 2: scare   = "ain't going to extend itself..."
                case 3: scare   = "is sad, extend it!"
                default: scare  = "is in jeopardy!"
                    
            }
            
            return "Your \(streakLen) game streak \(scare)"
            
        }
        
    }
    
}
