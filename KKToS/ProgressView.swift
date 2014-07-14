//
//  ProgressView.swift
//  KKToS
//
//  Created by Abe on 2014/7/14.
//  Copyright (c) 2014 Abe Wang. All rights reserved.
//

import Foundation
import UIKit

@objc protocol ProgressViewDelegate : NSObjectProtocol {
	@optional func timerTimeOutInProgressView(progressView: ProgressView!)
}

class ProgressView : UIView {

	var delegate: ProgressViewDelegate!
	var timer: NSTimer!
	var currentTime: NSTimeInterval = 10.0
	var countingDownTimeInterval: NSTimeInterval = 10.0
	var isRunning: Bool = false

	init(frame: CGRect) {
		super.init(frame: frame)
		self.layer.borderWidth = 1.0
		self.layer.borderColor = UIColor.blackColor().CGColor
		self.backgroundColor = UIColor.grayColor()
	}

	func startCountingDownWithTimeInterval(timeInterval: NSTimeInterval) {
		self.countingDownTimeInterval = timeInterval
		self.currentTime = timeInterval
		self.setNeedsDisplay()

		isRunning = true

		if timer {
			timer.invalidate()
		}
		timer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: Selector("timerAction"), userInfo: nil, repeats: true)
	}

	func timerAction() {
		if currentTime <= 0.0 {
			self.timerInvalidate()
			if delegate.respondsToSelector(Selector("timerTimeOutInProgressView:")) {
				delegate.timerTimeOutInProgressView!(self)
			}
			return
		}
		currentTime -= 0.02
		self.setNeedsDisplay()
	}

	func timerInvalidate() {
		if timer {
			timer.invalidate()
			isRunning = false
			currentTime = countingDownTimeInterval
			self.setNeedsDisplay()
		}
	}

	override func drawRect(rect: CGRect) {
		super.drawRect(rect)

		UIColor.greenColor().set()
		let valueRect: CGRect = CGRectMake(0.0, 0.0, CGRectGetWidth(self.bounds) * CGFloat(currentTime / countingDownTimeInterval), CGRectGetHeight(self.bounds))
		var valuePath: UIBezierPath = UIBezierPath(rect: valueRect)
		valuePath.fill()
	}
}
