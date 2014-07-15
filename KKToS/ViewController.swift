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
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.1)
        node.frame = touchNodeRect
		CATransaction.commit()
        touchNodeRect = currentNodeRect
        
        // Update Temp Node
        tempNodeLayer.frame = touchNodeRect
        tempNodeLayer.nodePosition = currentNodePosition
    }

	func _touchesEnded() {
		if tempNodeLayer.superlayer == nil {
			return
		}
		progressView.timerInvalidate()
		touchNodeLayer.frame = touchNodeRect
		tempNodeLayer.removeFromSuperlayer()

        var comboResult: Bool = self.handleComboNodes()
	}

	func handleComboNodes() -> Bool {

		var	comboNodePositions: [NodePosition] = []

		func addPositionToComboArray(position: NodePosition) {
			for comboNodePosition in comboNodePositions {
				if comboNodePosition.row == position.row && comboNodePosition.column == position.column {
					return
				}
			}
			comboNodePositions.append(position)
		}

		func comboNodeCount(below node: NodeLayer) -> Int {
			var count: Int = 0
			let nodePosition: NodePosition = node.nodePosition
			for comboNodePosition in comboNodePositions {
				if (comboNodePosition as NodePosition).column == nodePosition.column &&
					(comboNodePosition as NodePosition).row > nodePosition.row {
						count++
				}
			}
			return count
		}

        // Check combo nodes
		for rowIndex in 0..<nodes.count {
			var rowArray = nodes.objectAtIndex(rowIndex) as NSMutableArray
			for columnIndex in 0..<rowArray.count {
				let node: NodeLayer! = self.nodeLayer(position: NodePosition(row: rowIndex + 1, column: columnIndex + 1))
				var nodeOne: NodeLayer!
				var nodeTwo: NodeLayer!

				// Check Right
				if node.nodePosition.column + 2 <= worldView.columnCount {
					nodeOne = self.nodeLayer(position: NodePosition(row: node.nodePosition.row, column: node.nodePosition.column + 1))
					nodeTwo = self.nodeLayer(position: NodePosition(row: node.nodePosition.row, column: node.nodePosition.column + 2))
					if nodeOne.type == node.type && nodeTwo.type == node.type {
						addPositionToComboArray(nodeOne.nodePosition)
						addPositionToComboArray(nodeTwo.nodePosition)
					}
				}

				// Check Left
				if node.nodePosition.column - 2 >= 1 {
					nodeOne = self.nodeLayer(position: NodePosition(row: node.nodePosition.row, column: node.nodePosition.column - 1))
					nodeTwo = self.nodeLayer(position: NodePosition(row: node.nodePosition.row, column: node.nodePosition.column - 2))
					if nodeOne.type == node.type && nodeTwo.type == node.type {
						addPositionToComboArray(nodeOne.nodePosition)
						addPositionToComboArray(nodeTwo.nodePosition)
					}
				}

				// Check Up
				if node.nodePosition.row - 2 >= 1 {
					nodeOne = self.nodeLayer(position: NodePosition(row: node.nodePosition.row - 1, column: node.nodePosition.column))
					nodeTwo = self.nodeLayer(position: NodePosition(row: node.nodePosition.row - 2, column: node.nodePosition.column))
					if nodeOne.type == node.type && nodeTwo.type == node.type {
						addPositionToComboArray(nodeOne.nodePosition)
						addPositionToComboArray(nodeTwo.nodePosition)
					}
				}

				// Check Down
				if node.nodePosition.row + 2 <= worldView.rowCount {
					nodeOne = self.nodeLayer(position: NodePosition(row: node.nodePosition.row + 1, column: node.nodePosition.column))
					nodeTwo = self.nodeLayer(position: NodePosition(row: node.nodePosition.row + 2, column: node.nodePosition.column))
					if nodeOne.type == node.type && nodeTwo.type == node.type {
						addPositionToComboArray(nodeOne.nodePosition)
						addPositionToComboArray(nodeTwo.nodePosition)
					}
				}
			}
		}
        
        if comboNodePositions.count == 0 {
            return false
        }

		// Move node animations
		for comboNodePosition in comboNodePositions {
            let node: NodeLayer = self.nodeLayer(position: comboNodePosition)
			CATransaction.begin()
			CATransaction.setAnimationDuration(0.5)
            CATransaction.setCompletionBlock({node.removeFromSuperlayer()})
			node.hidden = true
			CATransaction.commit()
		}

		for rowIndex in 0..<nodes.count {
			var rowArray = nodes.objectAtIndex(rowIndex) as NSMutableArray
			for columnIndex in 0..<rowArray.count {
				let node: NodeLayer! = self.nodeLayer(position: NodePosition(row: rowIndex + 1, column: columnIndex + 1))
				let comboCount: Int = comboNodeCount(below: node)
				if comboCount != 0 {
					let delay = 1.0 * CGFloat(NSEC_PER_SEC)
					let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
					dispatch_after(time, dispatch_get_main_queue(), {
						CATransaction.begin()
						CATransaction.setAnimationDuration(1.0)
						var rect: CGRect = node.frame
						rect.origin.y += CGFloat(comboCount) * self.worldView.gridHeight
						node.frame = rect
						CATransaction.commit()
						})
				}
			}
		}

		// Updates node array by column
        for columnIndex in 0..<worldView.columnCount {
            // Phase 1 : Compute combo nodes count
            // Phase 2 : Remove combo nodes
            var comboCount: Int = 0
            for comboNodePosition in comboNodePositions {
                if comboNodePosition.column == columnIndex + 1 {
                    comboCount++
                    var rowArray: NSMutableArray = nodes.objectAtIndex(comboNodePosition.row - 1) as NSMutableArray
                    rowArray.removeObjectAtIndex(columnIndex)
                }
            }
            
            // Phase 3 : 由下往上找要掉下來的node，remove 往下 insert
            func comboNodePositionArrayContainsPosition(position: NodePosition) -> Bool {
                for comboNodePosition in comboNodePositions {
                    if comboNodePosition.column == position.column && comboNodePosition.row == position.row {
                        return true
                    }
                }
                return false
            }
            for var rowIndex = worldView.rowCount - 1; 0 <= rowIndex; rowIndex-- {
                if comboNodePositionArrayContainsPosition(NodePosition(row: rowIndex + 1, column: columnIndex + 1)) {
                    continue
                }
                
                let node: NodeLayer = self.nodeLayer(position: NodePosition(row: rowIndex + 1, column: columnIndex + 1))
                let comboCount: Int = comboNodeCount(below: node)
                if comboCount != 0 {
                    var originRowArray: NSMutableArray = nodes.objectAtIndex(node.nodePosition.row - 1) as NSMutableArray
                    var moveRowArray: NSMutableArray = nodes.objectAtIndex(node.nodePosition.row + comboCount - 1) as NSMutableArray
                    moveRowArray.insertObject(node, atIndex: columnIndex)
                    originRowArray.removeObjectAtIndex(columnIndex)
                    node.nodePosition.row += comboCount
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
                let node: NodeLayer = NodeLayer(nodeType: nodeType, nodePosition: NodePosition(row: addNodeIndex + 1, column: columnIndex + 1))
                worldView.layer.addSublayer(node)
                let nodeRect: CGRect = CGRectMake(worldView.gridHeight * CGFloat(columnIndex), worldView.gridHeight * CGFloat(addNodeIndex), worldView.gridHeight, worldView.gridHeight)
                var animationOriginRect: CGRect = nodeRect
                animationOriginRect.origin.y -= worldView.gridHeight * CGFloat(comboCount) + 30.0
                node.frame = CGRectInset(animationOriginRect, 5.0, 5.0)
                var rowArray: NSMutableArray = nodes.objectAtIndex(addNodeIndex) as NSMutableArray
                rowArray.insertObject(node, atIndex: columnIndex)
                
                let delay = 2.0 * CGFloat(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue(), {
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(1.5)
                    node.frame = CGRectInset(nodeRect, 5.0, 5.0)
                    CATransaction.commit()
                })
            }
        }
        
        return true
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
}
