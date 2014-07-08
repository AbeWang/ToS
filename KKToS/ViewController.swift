//
//  ViewController.swift
//  KKToS
//
//  Created by Abe on 2014/7/8.
//  Copyright (c) 2014年 Abe Wang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var worldView: WorldView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        worldView = WorldView(frame: CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 0.0), rowCount: 5, columnCount: 6)
        var worldRect: CGRect = worldView.frame
        worldRect.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(worldRect)
        worldView.frame = worldRect
        self.view.addSubview(worldView)
    }
}

