//
//  PlayStreak.swift
//  Ms Scoreminder
//
//  Created by Aaron Nance on 11/23/21.
//

import Foundation

typealias StreakSet = (recent: PlayStreak, longest: PlayStreak)

struct PlayStreak {
    
    private(set) var start: Date?
    private(set) var end: Date?
    
    /// Returns the number of days between the `start` and `end` or `nil` if there is no valid
    /// solution(e.g. one or both `Dates` are nil)
    ///
    /// - note: negative values indicate that the end `Date` predates start `Date`.
    var length: Int {
        
        guard   let start   = start,
                let end     = end
        else { return 0 /*EXIT*/ }
        
        let len = end.daysFrom(earlierDate: start) + 1
        
        return len
        
    }
    
    /// Returns a `Bool` indicating whether the `PlayStreak` includes today(`true`)
    var isCurrent: Bool { return end?.simple == Date().simple }
    
    init(_ d1: Date? = nil, _ d2: Date? = nil) {
        
        start   = d1
        end     = d2
        
    }
    
    /// Creates and returns a new `PlayStreak`
    /// If `with` `Date` is  less than 2 days from `self.start`, returns a new streak with old `start`
    /// `Date` but updated `end`
    /// else returns a new `PlayStreak` with `start` and `end` initialized to `with` `Date`
    ///
    /// - important: this method does not mutate `self`, be sure to capture results to
    /// originating variable as desired.
    func extend(with date: Date) -> PlayStreak {
        
        var extended    = self
        
        extended.start  = extended.start ?? date
        extended.end    = extended.end ?? date
  
        if date.daysFrom(earlierDate: extended.end!) > 1 {
            
            // start new streak
            extended.start  = date
            extended.end    = date
            
        } else {
            
            extended.end = date
            
        }
        
        assert(extended.length > 0)
        
        return extended
        
    }
    
}

extension PlayStreak: CustomStringConvertible {
    
    var description: String {
        
        let d1 = start  != nil ? start!.simple  : "nil"
        let d2 = end    != nil ? end!.simple    : "nil"
        
        return "\(d1) to \(d2) - length: \(length)"
        
    }
    
    var durationDescription: String { "\(length) days"}
    
}
