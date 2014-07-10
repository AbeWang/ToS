//
//  NodeLayer.swift
//  KKToS
//
//  Created by Abe on 2014/7/10.
//  Copyright (c) 2014年 Abe Wang. All rights reserved.
//

import QuartzCore
import UIKit

enum NodeLayerType {
    case RED, BLUE, YELLOW, PURPLE, GREEN, PINK, UNKNOWN
}

struct NodePosition {
    var row: Int = 0
    var column: Int = 0
}

class NodeLayer: CALayer {
    var type: NodeLayerType = .UNKNOWN
    var nodePosition: NodePosition = NodePosition()
    
    init(nodeType: NodeLayerType, nodePosition: NodePosition) {
        super.init()
        self.type = nodeType
        self.nodePosition = nodePosition
        self._init()
    }
    
    func _init() {
        self.contentsScale = UIScreen.mainScreen().scale
        self.cornerRadius = 5
        self.borderWidth = 1.0
        self.borderColor = UIColor.blackColor().CGColor
        
        switch type {
        case .RED:
            self.backgroundColor = UIColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 1.0).CGColor
        case .BLUE:
            self.backgroundColor = UIColor(red: 0.325, green: 0.741, blue: 0.937, alpha: 1.0).CGColor
        case .YELLOW:
            self.backgroundColor = UIColor(red: 0.949, green: 0.867, blue: 0.275, alpha: 1.0).CGColor
        case .PURPLE:
            self.backgroundColor = UIColor(red: 0.894, green: 0.2, blue: 0.965, alpha: 1.0).CGColor
        case .GREEN:
            self.backgroundColor = UIColor(red: 0.039, green: 0.886, blue: 0.267, alpha: 1.0).CGColor
        case .PINK:
            self.backgroundColor = UIColor(red: 1.0, green: 0.694, blue: 898, alpha: 1.0).CGColor
        case .UNKNOWN:
            fallthrough
        default:
            self.backgroundColor = UIColor.lightGrayColor().CGColor
        }
    }
}
