//
//  Timer.swift
//  Goe
//
//  Created by Kadhir M on 5/20/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import Foundation

class Timer {
    var timer = NSTimer()
    let duration: Double
    let completionHandler: () -> ()
    private var elapsedTime: Double = 0.0
    
    init(duration: Double, completionHandler: () -> ()) {
        self.duration = duration
        self.completionHandler = completionHandler
    }
    
    func start() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(Timer.tick), userInfo: nil, repeats: true)
    }
    
    func stop() {
        self.timer.invalidate()
    }
    
    @objc private func tick() {
        self.elapsedTime += 1.0
        if self.elapsedTime == self.duration {
            self.stop()
            self.completionHandler()
            self.elapsedTime = 0.0
        }
    }
    
    deinit {
        self.stop()
    }
}