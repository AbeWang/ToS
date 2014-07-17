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

    var touchNodeLayer: NodeLayer!
    var touchNodeRect: CGRect!
    var translucentNodeLayer: NodeLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = UIColor.lightGrayColor()

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
        
        translucentNodeLayer = NodeLayer(nodeType: .UNKNOWN, nodeLocation: NodeLocation(row: 0, column: 0))
        translucentNodeLayer.opacity = 0.2

		while self.handleComboNodesAnimated(false) { NSLog("Handle combo nodes...") }
    }
    
    func createNodes(#rowCount: Int, columnCount:Int) -> NSMutableArray {
        var resultArray: NSMutableArray = NSMutableArray()
        for rowIndex in 0..<rowCount {
            var rowArray: NSMutableArray = NSMutableArray()
            for columnIndex in 0..<columnCount {
                var nodeType: NodeLayerType
                switch arc4random() % 6 {
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
                let nodeLocation: NodeLocation = NodeLocation(row: rowIndex + 1, column: columnIndex + 1)
                let node: NodeLayer = NodeLayer(nodeType: nodeType, nodeLocation: nodeLocation)
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
    
    func nodeLayer(#location: NodeLocation) -> NodeLayer {
        let rowArray = nodes.objectAtIndex(location.row - 1) as NSMutableArray
        return rowArray.objectAtIndex(location.column - 1) as NodeLayer
    }
    
    func touchPosition(position: CGPoint) -> NodeLocation {
        let row: Int = Int(floor(position.y / worldView.gridHeight) + 1)
        let column: Int = Int(floor(position.x / worldView.gridHeight) + 1)
        return NodeLocation(row: row, column: column)
    }

    // Swap nodes
    func moveTouchNodeTo(#node: NodeLayer) {
        let touchNodeLocation: NodeLocation = touchNodeLayer.location
        let currentNodeLocation: NodeLocation = node.location
        var touchRowArray: NSMutableArray = nodes.objectAtIndex(touchNodeLocation.row - 1) as NSMutableArray
        var currentRowArray: NSMutableArray = nodes.objectAtIndex(currentNodeLocation.row - 1) as NSMutableArray
        
        // Updates Node Array
        if currentNodeLocation.row == touchNodeLocation.row {
            currentRowArray.exchangeObjectAtIndex(touchNodeLocation.column - 1, withObjectAtIndex: currentNodeLocation.column - 1)
        }
        else {
            let touchNode: NodeLayer = touchRowArray.objectAtIndex(touchNodeLocation.column - 1) as NodeLayer
            let currentNode: NodeLayer = currentRowArray.objectAtIndex(currentNodeLocation.column - 1) as NodeLayer
            touchRowArray.insertObject(currentNode, atIndex: touchNodeLocation.column - 1)
            currentRowArray.insertObject(touchNode, atIndex: currentNodeLocation.column - 1)
            touchRowArray.removeObjectAtIndex(touchNodeLocation.column)
            currentRowArray.removeObjectAtIndex(currentNodeLocation.column)
        }
        
        // Update Node Location
        node.location = touchNodeLocation
        touchNodeLayer.location = currentNodeLocation
        
        // Update Node Frame
		let currentNodeRect = node.frame
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.1)
        node.frame = touchNodeRect
		CATransaction.commit()
        touchNodeRect = currentNodeRect
        
        // Update TranslucentNodeLayer Node
        translucentNodeLayer.frame = touchNodeRect
        translucentNodeLayer.location = currentNodeLocation
    }

	func _touchesEnded() {
		if translucentNodeLayer.superlayer == nil {
			return
		}
		progressView.timerInvalidate()
		touchNodeLayer.frame = touchNodeRect
		translucentNodeLayer.removeFromSuperlayer()

        while self.handleComboNodesAnimated(true) { NSLog("Handle combo nodes...") }
	}

	func handleComboNodesAnimated(animated: Bool) -> Bool {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
		var	comboNodeLocations: [NodeLocation] = []
        var running: Bool = true

		func addLocationToComboArray(location: NodeLocation) {
			for comboNodeLocation in comboNodeLocations {
				if comboNodeLocation.row == location.row && comboNodeLocation.column == location.column {
					return
				}
			}
			comboNodeLocations.append(location)
		}

		func comboNodeCount(below node: NodeLayer) -> Int {
			var count: Int = 0
			let nodeLocation: NodeLocation = node.location
			for comboNodeLocation in comboNodeLocations {
				if (comboNodeLocation as NodeLocation).column == nodeLocation.column &&
					(comboNodeLocation as NodeLocation).row > nodeLocation.row {
						count++
				}
			}
			return count
		}

        // Check combo nodes
		for rowIndex in 0..<nodes.count {
			var rowArray = nodes.objectAtIndex(rowIndex) as NSMutableArray
			for columnIndex in 0..<rowArray.count {
				let node: NodeLayer! = self.nodeLayer(location: NodeLocation(row: rowIndex + 1, column: columnIndex + 1))
				var nodeOne: NodeLayer!
				var nodeTwo: NodeLayer!

				// Check Right
				if node.location.column + 2 <= worldView.columnCount {
					nodeOne = self.nodeLayer(location: NodeLocation(row: node.location.row, column: node.location.column + 1))
					nodeTwo = self.nodeLayer(location: NodeLocation(row: node.location.row, column: node.location.column + 2))
					if nodeOne.type == node.type && nodeTwo.type == node.type {
						addLocationToComboArray(nodeOne.location)
						addLocationToComboArray(nodeTwo.location)
					}
				}

				// Check Left
				if node.location.column - 2 >= 1 {
					nodeOne = self.nodeLayer(location: NodeLocation(row: node.location.row, column: node.location.column - 1))
					nodeTwo = self.nodeLayer(location: NodeLocation(row: node.location.row, column: node.location.column - 2))
					if nodeOne.type == node.type && nodeTwo.type == node.type {
						addLocationToComboArray(nodeOne.location)
						addLocationToComboArray(nodeTwo.location)
					}
				}

				// Check Up
				if node.location.row - 2 >= 1 {
					nodeOne = self.nodeLayer(location: NodeLocation(row: node.location.row - 1, column: node.location.column))
					nodeTwo = self.nodeLayer(location: NodeLocation(row: node.location.row - 2, column: node.location.column))
					if nodeOne.type == node.type && nodeTwo.type == node.type {
						addLocationToComboArray(nodeOne.location)
						addLocationToComboArray(nodeTwo.location)
					}
				}

				// Check Down
				if node.location.row + 2 <= worldView.rowCount {
					nodeOne = self.nodeLayer(location: NodeLocation(row: node.location.row + 1, column: node.location.column))
					nodeTwo = self.nodeLayer(location: NodeLocation(row: node.location.row + 2, column: node.location.column))
					if nodeOne.type == node.type && nodeTwo.type == node.type {
						addLocationToComboArray(nodeOne.location)
						addLocationToComboArray(nodeTwo.location)
					}
				}
			}
		}
        
        if comboNodeLocations.count == 0 {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            return false
        }

		// Move node animations
		for comboNodeLocation in comboNodeLocations {
            let node: NodeLayer = self.nodeLayer(location: comboNodeLocation)
			if animated {
				CATransaction.begin()
				CATransaction.setAnimationDuration(0.3)
				CATransaction.setCompletionBlock({ node.removeFromSuperlayer() })
				node.frame = CGRectInset(node.frame, CGRectGetWidth(node.frame) / 2, CGRectGetWidth(node.frame) / 2)
				CATransaction.commit()
			}
			else {
				node.removeFromSuperlayer()
			}
		}

		for rowIndex in 0..<nodes.count {
			var rowArray = nodes.objectAtIndex(rowIndex) as NSMutableArray
			for columnIndex in 0..<rowArray.count {
				let node: NodeLayer! = self.nodeLayer(location: NodeLocation(row: rowIndex + 1, column: columnIndex + 1))
				let comboCount: Int = comboNodeCount(below: node)
				if comboCount != 0 {
					if animated {
						let delay = 0.2 * CGFloat(NSEC_PER_SEC)
						let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
						dispatch_after(time, dispatch_get_main_queue(), {
							CATransaction.begin()
							CATransaction.setAnimationDuration(0.5)
							var rect: CGRect = node.frame
							rect.origin.y += CGFloat(comboCount) * self.worldView.gridHeight
							node.frame = rect
							CATransaction.commit()
						})
					}
					else {
						var rect: CGRect = node.frame
						rect.origin.y += CGFloat(comboCount) * self.worldView.gridHeight
						node.frame = rect
					}
				}
			}
		}
        
		// Updates node array by column
        for columnIndex in 0..<worldView.columnCount {
            // Phase 1 : Compute combo nodes count
            // Phase 2 : Remove combo nodes
            var comboCount: Int = 0
            for comboNodeLocation in comboNodeLocations {
                if comboNodeLocation.column == columnIndex + 1 {
                    comboCount++
                    var rowArray: NSMutableArray = nodes.objectAtIndex(comboNodeLocation.row - 1) as NSMutableArray
                    rowArray.removeObjectAtIndex(columnIndex)
                }
            }
            
            // Phase 3 : 由下往上找要掉下來的node，remove 往下 insert
            func comboNodeLocationArrayContainsLocation(location: NodeLocation) -> Bool {
                for comboNodeLocation in comboNodeLocations {
                    if comboNodeLocation.column == location.column && comboNodeLocation.row == location.row {
                        return true
                    }
                }
                return false
            }
            for var rowIndex = worldView.rowCount - 1; 0 <= rowIndex; rowIndex-- {
                if comboNodeLocationArrayContainsLocation(NodeLocation(row: rowIndex + 1, column: columnIndex + 1)) {
                    continue
                }
                
                let node: NodeLayer = self.nodeLayer(location: NodeLocation(row: rowIndex + 1, column: columnIndex + 1))
                let comboCount: Int = comboNodeCount(below: node)
                if comboCount != 0 {
                    var originRowArray: NSMutableArray = nodes.objectAtIndex(node.location.row - 1) as NSMutableArray
                    var moveRowArray: NSMutableArray = nodes.objectAtIndex(node.location.row + comboCount - 1) as NSMutableArray
                    moveRowArray.insertObject(node, atIndex: columnIndex)
                    originRowArray.removeObjectAtIndex(columnIndex)
                    node.location.row += comboCount
                }
            }
            
            // Phase 4 : Insert new nodes to TOP
            for addNodeIndex in 0..<comboCount {
                var nodeType: NodeLayerType
                switch arc4random() % 6 {
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
                let node: NodeLayer = NodeLayer(nodeType: nodeType, nodeLocation: NodeLocation(row: addNodeIndex + 1, column: columnIndex + 1))
                let nodeRect: CGRect = CGRectMake(worldView.gridHeight * CGFloat(columnIndex), worldView.gridHeight * CGFloat(addNodeIndex), worldView.gridHeight, worldView.gridHeight)
                var animationOriginRect: CGRect = nodeRect
                animationOriginRect.origin.y -= worldView.gridHeight * CGFloat(comboCount) + 30.0
                node.frame = CGRectInset(animationOriginRect, 5.0, 5.0)
                node.hidden = true
                worldView.layer.addSublayer(node)
                
                var rowArray: NSMutableArray = nodes.objectAtIndex(addNodeIndex) as NSMutableArray
                rowArray.insertObject(node, atIndex: columnIndex)

				if animated {
					let delay = 0.4 * CGFloat(NSEC_PER_SEC)
					let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
					dispatch_after(time, dispatch_get_main_queue(), {
						node.hidden = false
						CATransaction.begin()
						CATransaction.setAnimationDuration(0.5)
						CATransaction.setCompletionBlock({ running = false })
						node.frame = CGRectInset(nodeRect, 5.0, 5.0)
						CATransaction.commit()
					})
				}
				else {
					node.hidden = false
					node.frame = CGRectInset(nodeRect, 5.0, 5.0)
					running = false
				}
            }
        }

        while running {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.1))
        }
        
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
        return true
	}

	func timerTimeOutInProgressView(progressView: ProgressView!) {
		self._touchesEnded()
	}

    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        let touch: UITouch = touches.anyObject() as UITouch
        var touchPosition: CGPoint = touch.locationInView(worldView)
        
        if touchPosition.y < 0 {
            return
        }
        
        let touchLocation: NodeLocation = self.touchPosition(touchPosition)
        touchNodeLayer = self.nodeLayer(location: touchLocation)
        touchNodeRect = touchNodeLayer.frame
        
        if translucentNodeLayer.superlayer == nil {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            translucentNodeLayer.frame = touchNodeRect
            CATransaction.commit()
            translucentNodeLayer.type = touchNodeLayer.type
            translucentNodeLayer.location = touchLocation
            worldView.layer.insertSublayer(translucentNodeLayer, below: touchNodeLayer)
        }
    }
    
    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
        if translucentNodeLayer.superlayer == nil {
            return
        }
        
        let touch: UITouch = touches.anyObject() as UITouch
        var touchPosition: CGPoint = touch.locationInView(worldView)
        var nodeRect: CGRect = touchNodeLayer.frame
        nodeRect.origin.x = touchPosition.x - nodeRect.size.width / 2
        nodeRect.origin.y = touchPosition.y - nodeRect.size.width / 2
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        touchNodeLayer.frame = nodeRect
        CATransaction.commit()
        
        if touchPosition.y < 0 {
           touchPosition.y = 0
        }
        
        let currentNodeLocation: NodeLocation = self.touchPosition(touchPosition)
        if currentNodeLocation.row != touchNodeLayer.location.row ||
           currentNodeLocation.column != touchNodeLayer.location.column {

			if !progressView.isRunning {
				progressView.startCountingDownWithTimeInterval(6.0)
			}
            self.moveTouchNodeTo(node: self.nodeLayer(location: currentNodeLocation))
        }
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        self._touchesEnded()
    }
}
