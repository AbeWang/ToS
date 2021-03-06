//
//  NodeLayer.swift
//  KKToS
//
//  Created by Abe on 2014/7/10.
//  Copyright (c) 2014 Abe Wang. All rights reserved.
//

import QuartzCore
import UIKit

enum NodeLayerType {
    case RED, BLUE, YELLOW, PURPLE, GREEN, PINK, UNKNOWN
}

struct NodeLocation {
    var row = 0
    var column = 0
}

class NodeLayer: CALayer {
    var _type = NodeLayerType.UNKNOWN
    var _nodeLocation = NodeLocation()
    
    var location: NodeLocation {
        get {
            return _nodeLocation
        }
        set {
            _nodeLocation = newValue
        }
    }
    
    var type: NodeLayerType {
        get {
            return _type
        }
        set {
            _type = newValue
            switch _type {
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
                self.backgroundColor = UIColor(red: 1.0, green: 0.753, blue: 0.796, alpha: 1.0).CGColor
            case .UNKNOWN:
                fallthrough
            default:
                self.backgroundColor = UIColor.lightGrayColor().CGColor
            }
        }
    }
    
    init(nodeType: NodeLayerType, nodeLocation: NodeLocation) {
        super.init()
        self._init()
        self.type = nodeType
        self.location = nodeLocation
    }

	required init(coder aDecoder: NSCoder!) {
		super.init(coder: aDecoder)
	}

	override init(layer: AnyObject!) {
		super.init(layer: layer)
	}

    func _init() {
        self.contentsScale = UIScreen.mainScreen().scale
        self.cornerRadius = 12
        self.borderWidth = 2.0
        self.borderColor = UIColor.blackColor().CGColor
    }
}
