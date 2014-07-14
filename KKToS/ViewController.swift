//
//  ViewController.swift
//  KKToS
//
//  Created by Abe on 2014/7/8.
//  Copyright (c) 2014 Abe Wang. All rights reserved.
//

import UIKit
import QuartzCore

class ViewController: UIViewController, ProgressViewDelegate {

	var progressView: ProgressView!
    var worldView: WorldView!
    var nodes: NSMutableArray!
    
    var tempNodeLayer: NodeLayer!
    var touchNodeLayer: NodeLayer!
    var touchNodeRect: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        worldView = WorldView(frame: CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 0.0), rowCount: 5, columnCount: 6)
        var worldRect: CGRect = worldView.frame
        worldRect.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(worldRect)
        worldView.frame = worldRect
        self.view.addSubview(worldView)

		progressView = ProgressView(frame: CGRectMake(0.0, CGRectGetMinY(worldView.frame) - 20.0, CGRectGetWidth(self.view.bounds), 20.0))
		progressView.delegate = self
		self.view.addSubview(progressView)

        nodes = self.createNodes(rowCount: worldView.rowCount, columnCount: worldView.columnCount)
        self.addNodesToWorldView()
        
        tempNodeLayer = NodeLayer(nodeType: .UNKNOWN, nodePosition: NodePosition(row: 0, column: 0))
        tempNodeLayer.opacity = 0.2
    }
    
    func createNodes(#rowCount: Int, columnCount:Int) -> NSMutableArray {
        var resultArray: NSMutableArray = NSMutableArray()
        for rowIndex in 0..<rowCount {
            var rowArray: NSMutableArray = NSMutableArray()
            for columnIndex in 0..<columnCount {
                var nodeType: NodeLayerType
                switch random() % 6 {
                case 0:
                    nodeType = .RED
                case 1:
                    nodeType = .BLUE
                case 2:
                    nodeType = .YELLOW
                case 3:
                    nodeType = .PURPLE
                case 4:
                    nodeType = .GREEN
                case 5:
                    nodeType = .PINK
                default:
                    nodeType = .UNKNOWN
                }
                let nodePosition: NodePosition = NodePosition(row: rowIndex + 1, column: columnIndex + 1)
                let node: NodeLayer = NodeLayer(nodeType: nodeType, nodePosition: nodePosition)
                rowArray.addObject(node)
            }
            resultArray.addObject(rowArray)
        }
        return resultArray
    }

    func addNodesToWorldView() {
        for rowIndex in 0..<worldView.rowCount {
            var rowArray: NSMutableArray = nodes.objectAtIndex(rowIndex) as NSMutableArray
            for columnIndex in 0..<worldView.columnCount {
                var nodeLayer: NodeLayer = rowArray.objectAtIndex(columnIndex) as NodeLayer
                var nodeRect: CGRect = CGRectMake(worldView.gridHeight * CGFloat(columnIndex), worldView.gridHeight * CGFloat(rowIndex), worldView.gridHeight, worldView.gridHeight)
                nodeLayer.frame = CGRectInset(nodeRect, 5.0, 5.0)
                worldView.layer.addSublayer(nodeLayer)
            }
        }
    }
    
    func nodeLayer(#position: NodePosition) -> NodeLayer {
        let rowArray = nodes.objectAtIndex(position.row - 1) as NSMutableArray
        return rowArray.objectAtIndex(position.column - 1) as NodeLayer
    }
    
    func touchPosition(position: CGPoint) -> NodePosition {
        let row: Int = Int(floor(position.y / worldView.gridHeight) + 1)
        let column: Int = Int(floor(position.x / worldView.gridHeight) + 1)
        return NodePosition(row: row, column: column)
    }

    func moveTouchNodeTo(#node: NodeLayer) {
        let touchNodePosition: NodePosition = touchNodeLayer.nodePosition
        let currentNodePosition: NodePosition = node.nodePosition
        var touchRowArray: NSMutableArray = nodes.objectAtIndex(touchNodePosition.row - 1) as NSMutableArray
        var currentRowArray: NSMutableArray = nodes.objectAtIndex(currentNodePosition.row - 1) as NSMutableArray
        
        // Set Nodes Array
        if currentNodePosition.row == touchNodePosition.row {
            currentRowArray.exchangeObjectAtIndex(touchNodePosition.column - 1, withObjectAtIndex: currentNodePosition.column - 1)
        }
        else {
            let touchNode: NodeLayer = touchRowArray.objectAtIndex(touchNodePosition.column - 1) as NodeLayer
            let currentNode: NodeLayer = currentRowArray.objectAtIndex(currentNodePosition.column - 1) as NodeLayer
            touchRowArray.insertObject(currentNode, atIndex: touchNodePosition.column - 1)
            currentRowArray.insertObject(touchNode, atIndex: currentNodePosition.column - 1)
            touchRowArray.removeObjectAtIndex(touchNodePosition.column)
            currentRowArray.removeObjectAtIndex(currentNodePosition.column)
        }
        
        // Set Node Position
        node.nodePosition = touchNodePosition
        touchNodeLayer.nodePosition = currentNodePosition
        
        // Set Node Frame
        let currentNodeRect = node.frame
        node.frame = touchNodeRect
        touchNodeRect = currentNodeRect
        
        // Update Temp Node
        tempNodeLayer.frame = touchNodeRect
        tempNodeLayer.nodePosition = currentNodePosition
    }

	func timerTimeOutInProgressView(progressView: ProgressView!) {
		UIApplication.sharedApplication().beginIgnoringInteractionEvents()
		self._touchesEnded()

		let delay = 1.0 * CGFloat(NSEC_PER_SEC)
		let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
		dispatch_after(time, dispatch_get_main_queue(), {
			UIApplication.sharedApplication().endIgnoringInteractionEvents()
		})
	}

    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        let touch: UITouch = touches.anyObject() as UITouch
        var touchLocation: CGPoint = touch.locationInView(worldView)
        
        if touchLocation.y < 0 {
            return
        }
        
        let touchPosition: NodePosition = self.touchPosition(touchLocation)
        touchNodeLayer = self.nodeLayer(position: touchPosition)
        touchNodeRect = touchNodeLayer.frame
        
        if tempNodeLayer.superlayer == nil {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            tempNodeLayer.frame = touchNodeRect
            CATransaction.commit()
            tempNodeLayer.type = touchNodeLayer.type
            tempNodeLayer.nodePosition = touchPosition
            worldView.layer.insertSublayer(tempNodeLayer, below: touchNodeLayer)
        }
    }
    
    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
        if tempNodeLayer.superlayer == nil {
            return
        }
        
        let touch: UITouch = touches.anyObject() as UITouch
        var touchLocation: CGPoint = touch.locationInView(worldView)
        var nodeRect: CGRect = touchNodeLayer.frame
        nodeRect.origin.x = touchLocation.x - nodeRect.size.width / 2
        nodeRect.origin.y = touchLocation.y - nodeRect.size.width / 2
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        touchNodeLayer.frame = nodeRect
        CATransaction.commit()
        
        if touchLocation.y < 0 {
           touchLocation.y = 0
        }
        
        let currentNodePosition: NodePosition = self.touchPosition(touchLocation)
        if currentNodePosition.row != touchNodeLayer.nodePosition.row ||
           currentNodePosition.column != touchNodeLayer.nodePosition.column {

			if !progressView.isRunning {
				progressView.startCountingDownWithTimeInterval(6.0)
			}
            self.moveTouchNodeTo(node: self.nodeLayer(position: currentNodePosition))
        }
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        self._touchesEnded()
    }

	func _touchesEnded() {
		if tempNodeLayer.superlayer == nil {
			return
		}
		progressView.timerInvalidate()
		touchNodeLayer.frame = touchNodeRect
		tempNodeLayer.removeFromSuperlayer()

		// Detect combo & Remove nodes
		// Add new nodes
	}
}
