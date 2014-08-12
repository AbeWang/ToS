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

    var touchNodeLayer: NodeLayer!
    var translucentNodeLayer: NodeLayer!
    var touchNodeRect: CGRect!
    
    let nodeManager = NodeManager()
    var nodes: NSMutableArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = UIColor.lightGrayColor()

        worldView = WorldView(frame: CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 0.0), rowCount: 5, columnCount: 6)
        var worldRect = worldView.frame
        worldRect.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(worldView.frame)
        worldView.frame = worldRect
        self.view.addSubview(worldView)

		progressView = ProgressView(frame: CGRectMake(0.0, CGRectGetMinY(worldView.frame) - 20.0, CGRectGetWidth(self.view.bounds), 20.0))
		progressView.delegate = self
		self.view.addSubview(progressView)

		// 把亂數產生的 Node 放到 worldView 上的適當位置
        nodes = nodeManager.createNodes(rowCount: worldView.rowCount, columnCount: worldView.columnCount)
        self.addNodesToWorldView()

		// translucent node 目的是用一個半透明的 node 來看目前的滑動位置
        translucentNodeLayer = NodeLayer(nodeType: .UNKNOWN, nodeLocation: NodeLocation(row: 0, column: 0))
        translucentNodeLayer.opacity = 0.2

        // 過濾首局盤面珠
		while handleComboNodesAnimated(false) { NSLog("Handle combo nodes...") }
    }

    /* 把 Nodes 加入到 world view 上 */
    func addNodesToWorldView() {
        for rowIndex in 0..<worldView.rowCount {
            var rowArray = nodes.objectAtIndex(rowIndex) as NSMutableArray
            for columnIndex in 0..<worldView.columnCount {
                var nodeLayer = rowArray.objectAtIndex(columnIndex) as NodeLayer
                var nodeRect = CGRectMake(worldView.gridHeight * CGFloat(columnIndex), worldView.gridHeight * CGFloat(rowIndex), worldView.gridHeight, worldView.gridHeight)
                nodeLayer.frame = CGRectInset(nodeRect, 5.0, 5.0)
                worldView.layer.addSublayer(nodeLayer)
            }
        }
    }
    
    /* 取得 nodes 中某一個 location 的 node */
    func nodeLayer(#location: NodeLocation) -> NodeLayer {
        let rowArray = nodes.objectAtIndex(location.row - 1) as NSMutableArray
        return rowArray.objectAtIndex(location.column - 1) as NodeLayer
    }
    
    /* 把 worldView 中手指按下的位置轉換成 Node Location */
    func nodeLocationInWorldView(position: CGPoint) -> NodeLocation {
        let row = Int(floor(position.y / worldView.gridHeight) + 1)
        let column = Int(floor(position.x / worldView.gridHeight) + 1)
        return NodeLocation(row: row, column: column)
    }

    /* 讓某個 node 與 touch node 彼此交換位置 */
    func swapNodeWithTouchNode(node: NodeLayer) {
        let touchNodeLocation = touchNodeLayer.location
        let currentNodeLocation = node.location
        var touchRowArray = nodes.objectAtIndex(touchNodeLocation.row - 1) as NSMutableArray
        var currentRowArray = nodes.objectAtIndex(currentNodeLocation.row - 1) as NSMutableArray
        
        // 更新兩個 node 在 nodes array 中的位置
        if currentNodeLocation.row == touchNodeLocation.row {
            currentRowArray.exchangeObjectAtIndex(touchNodeLocation.column - 1, withObjectAtIndex: currentNodeLocation.column - 1)
        }
        else {
            let currentNode = currentRowArray.objectAtIndex(currentNodeLocation.column - 1) as NodeLayer
            touchRowArray.insertObject(currentNode, atIndex: touchNodeLocation.column - 1)
            currentRowArray.insertObject(touchNodeLayer, atIndex: currentNodeLocation.column - 1)
            touchRowArray.removeObjectAtIndex(touchNodeLocation.column)
            currentRowArray.removeObjectAtIndex(currentNodeLocation.column)
        }
        
        // 更新兩個 node 的 location
        node.location = touchNodeLocation
        touchNodeLayer.location = currentNodeLocation
        
        // 更新兩個 node 的 frame
		let currentNodeRect = node.frame
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.15)
        node.frame = touchNodeRect
		CATransaction.commit()
        touchNodeRect = currentNodeRect
        
        // 移動半透明 Node 的位置
        translucentNodeLayer.frame = touchNodeRect
        translucentNodeLayer.location = touchNodeLayer.location
    }

    /* 消除目前 world view 畫面上的 combo nodes */
    /* 回傳 true 表示有消除 combo nodes，false 則表示畫面上無 combo nodes */
	func handleComboNodesAnimated(animated: Bool) -> Bool {
		var	comboNodeLocations: [NodeLocation] = []
        var running = true

		func addLocation(location: NodeLocation) {
			for comboNodeLocation in comboNodeLocations {
				if comboNodeLocation.row == location.row && comboNodeLocation.column == location.column {
					return
				}
			}
			comboNodeLocations.append(location)
		}

        // 計算某 node 下面有幾個 combo nodes
		func comboNodeCount(below node: NodeLayer) -> Int {
			var count = 0
			let nodeLocation = node.location
			for comboNodeLocation in comboNodeLocations {
				if (comboNodeLocation as NodeLocation).column == nodeLocation.column &&
					(comboNodeLocation as NodeLocation).row > nodeLocation.row {
						count++
				}
			}
			return count
		}
        
        // 檢查 combo node array 中是否有包含某個 location 的 node
        func comboNodeLocationArrayContainsLocation(location: NodeLocation) -> Bool {
            for comboNodeLocation in comboNodeLocations {
                if comboNodeLocation.column == location.column && comboNodeLocation.row == location.row {
                    return true
                }
            }
            return false
        }
        
        // 鎖住畫面不讓使用者移動
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()

        // 找出目前 world view 中的所有 combo nodes 並加入到 array 中
		for rowIndex in 0..<nodes.count {
			var rowArray = nodes.objectAtIndex(rowIndex) as NSMutableArray
			for columnIndex in 0..<rowArray.count {
				let comboNodeOne: NodeLayer! = self.nodeLayer(location: NodeLocation(row: rowIndex + 1, column: columnIndex + 1))
				var comboNodeTwo: NodeLayer!
				var comboNodeThree: NodeLayer!

				// 檢查 comboNodeOne 右邊的兩顆是否為相同的 type
				if comboNodeOne.location.column + 2 <= worldView.columnCount {
					comboNodeTwo = self.nodeLayer(location: NodeLocation(row: comboNodeOne.location.row, column: comboNodeOne.location.column + 1))
					comboNodeThree = self.nodeLayer(location: NodeLocation(row: comboNodeOne.location.row, column: comboNodeOne.location.column + 2))
					if comboNodeOne.type == comboNodeTwo.type && comboNodeOne.type == comboNodeThree.type {
						addLocation(comboNodeTwo.location)
						addLocation(comboNodeThree.location)
					}
				}

				// 檢查 comboNodeOne 左邊的兩顆是否為相同的 type
				if comboNodeOne.location.column - 2 >= 1 {
					comboNodeTwo = self.nodeLayer(location: NodeLocation(row: comboNodeOne.location.row, column: comboNodeOne.location.column - 1))
					comboNodeThree = self.nodeLayer(location: NodeLocation(row: comboNodeOne.location.row, column: comboNodeOne.location.column - 2))
					if comboNodeOne.type == comboNodeTwo.type && comboNodeOne.type == comboNodeThree.type {
						addLocation(comboNodeTwo.location)
						addLocation(comboNodeThree.location)
					}
				}

				// 檢查 comboNodeOne 上方的兩顆是否為相同的 type
				if comboNodeOne.location.row - 2 >= 1 {
					comboNodeTwo = self.nodeLayer(location: NodeLocation(row: comboNodeOne.location.row - 1, column: comboNodeOne.location.column))
					comboNodeThree = self.nodeLayer(location: NodeLocation(row: comboNodeOne.location.row - 2, column: comboNodeOne.location.column))
					if comboNodeOne.type == comboNodeTwo.type && comboNodeOne.type == comboNodeThree.type {
						addLocation(comboNodeTwo.location)
						addLocation(comboNodeThree.location)
					}
				}

				// 檢查 comboNodeOne 下方的兩顆是否為相同的 type
				if comboNodeOne.location.row + 2 <= worldView.rowCount {
					comboNodeTwo = self.nodeLayer(location: NodeLocation(row: comboNodeOne.location.row + 1, column: comboNodeOne.location.column))
					comboNodeThree = self.nodeLayer(location: NodeLocation(row: comboNodeOne.location.row + 2, column: comboNodeOne.location.column))
					if comboNodeOne.type == comboNodeTwo.type && comboNodeOne.type == comboNodeThree.type {
						addLocation(comboNodeTwo.location)
						addLocation(comboNodeThree.location)
					}
				}
			}
		}
        
        // 若沒有 combo node 則結束此回合
        if comboNodeLocations.count == 0 {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            return false
        }

		// 移除畫面上的 Combo Nodes，並把 Combo Nodes 上層的 Nodes 往下掉落
		for comboNodeLocation in comboNodeLocations {
            let node = self.nodeLayer(location: comboNodeLocation)
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
				let comboCount = comboNodeCount(below: node)
				if comboCount != 0 {
					if animated {
						let delay = 0.2 * Float(NSEC_PER_SEC)
						let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
						dispatch_after(time, dispatch_get_main_queue(), {
							CATransaction.begin()
							CATransaction.setAnimationDuration(0.5)
							var rect = node.frame
							rect.origin.y += CGFloat(comboCount) * self.worldView.gridHeight
							node.frame = rect
							CATransaction.commit()
						})
					}
					else {
						var rect = node.frame
						rect.origin.y += CGFloat(comboCount) * self.worldView.gridHeight
						node.frame = rect
					}
				}
			}
		}
        
		// 更新 Nodes Array，以每個 column 來處理
        for columnIndex in 0..<worldView.columnCount {
            // Phase 1 : 計算每一行的 Combo Nodes 數量
            // Phase 2 : 從 nodes array 中移除這些 Combo Nodes
            var comboCount = 0
            for comboNodeLocation in comboNodeLocations {
                if comboNodeLocation.column == columnIndex + 1 {
                    comboCount++
                    var rowArray: NSMutableArray = nodes.objectAtIndex(comboNodeLocation.row - 1) as NSMutableArray
                    rowArray.removeObjectAtIndex(columnIndex)
                }
            }
            
            // Phase 3 : 在每一行中，由下開始往上找會掉落的珠子，將它往下 insert 並從先前的位置移除
            for var rowIndex = worldView.rowCount - 1; 0 <= rowIndex; rowIndex-- {
                if comboNodeLocationArrayContainsLocation(NodeLocation(row: rowIndex + 1, column: columnIndex + 1)) {
                    // 忽略 combo node 自己
                    continue
                }
                
                let node = self.nodeLayer(location: NodeLocation(row: rowIndex + 1, column: columnIndex + 1))
                let comboCount = comboNodeCount(below: node)
                if comboCount != 0 {
                    var originRowArray = nodes.objectAtIndex(node.location.row - 1) as NSMutableArray
                    var moveRowArray = nodes.objectAtIndex(node.location.row + comboCount - 1) as NSMutableArray
                    moveRowArray.insertObject(node, atIndex: columnIndex)
                    originRowArray.removeObjectAtIndex(columnIndex)
                    node.location.row += comboCount
                }
            }
            
            // Phase 4 : 建立新落珠，由上往下掉落來填滿畫面
            for addNodeIndex in 0..<comboCount {
				let nodeTypeArray: [NodeLayerType] = [.RED, .BLUE, .YELLOW, .PURPLE, .GREEN, .PINK]
                let node = NodeLayer(nodeType: nodeTypeArray[Int(arc4random() % 6)], nodeLocation: NodeLocation(row: addNodeIndex + 1, column: columnIndex + 1))
                let nodeRect = CGRectMake(worldView.gridHeight * CGFloat(columnIndex), worldView.gridHeight * CGFloat(addNodeIndex), worldView.gridHeight, worldView.gridHeight)
                var animationRect = nodeRect
                animationRect.origin.y -= worldView.gridHeight * CGFloat(comboCount) + 30.0
                node.frame = CGRectInset(animationRect, 5.0, 5.0)
                node.hidden = true
                worldView.layer.addSublayer(node)
                
                var rowArray = nodes.objectAtIndex(addNodeIndex) as NSMutableArray
                rowArray.insertObject(node, atIndex: columnIndex)

				if animated {
					let delay = 0.4 * Float(NSEC_PER_SEC)
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

        // 用 runloop 先卡住，一直等到 running tag 變為 false 後再繼續往下走
        while running {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.1))
        }
        
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
        return true
	}

    /* ProgressView Delegate */
	func timerTimeOutInProgressView(progressView: ProgressView!) {
		self._touchesEnded()
	}
    
    func _touchesEnded() {
        if translucentNodeLayer.superlayer == nil {
            return
        }

        // Touch 時間結束後，把 touch node 移回到最後的置換位置
        progressView.timerInvalidate()
        touchNodeLayer.frame = touchNodeRect
        translucentNodeLayer.removeFromSuperlayer()
        
        // 檢查 combo nodes 並消除，一直到沒有 combo 為止
        while handleComboNodesAnimated(true) { NSLog("Handle combo nodes...") }
    }

    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        let touch = touches.anyObject() as UITouch
        var touchPosition = touch.locationInView(worldView)
        
        if touchPosition.y < 0 {
            return
        }
        
        let touchLocation = self.nodeLocationInWorldView(touchPosition)
        touchNodeLayer = self.nodeLayer(location: touchLocation)
        touchNodeRect = touchNodeLayer.frame
        
        if translucentNodeLayer.superlayer == nil {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            translucentNodeLayer.frame = touchNodeRect
            CATransaction.commit()
            translucentNodeLayer.type = touchNodeLayer.type
            translucentNodeLayer.location = touchNodeLayer.location
            worldView.layer.insertSublayer(translucentNodeLayer, below: touchNodeLayer)
        }
    }
    
    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
        if translucentNodeLayer.superlayer == nil {
            return
        }
        
        let touch = touches.anyObject() as UITouch
        var touchPosition = touch.locationInView(worldView)
        var nodeRect = touchNodeLayer.frame
        nodeRect.origin.x = touchPosition.x - nodeRect.size.width / 2
        nodeRect.origin.y = touchPosition.y - nodeRect.size.width / 2
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        touchNodeLayer.frame = nodeRect
        CATransaction.commit()
        
        if touchPosition.y < 0 {
           touchPosition.y = 0
        }
        
        // 檢查 touch node 目前的 location 是否有移動到其它地方
        let currentNodeLocation = self.nodeLocationInWorldView(touchPosition)
        if currentNodeLocation.row != touchNodeLayer.location.row ||
           currentNodeLocation.column != touchNodeLayer.location.column {

            // 若 progress 還沒有進行秒數倒數，則開始倒數 6 秒
			if !progressView.isRunning {
				progressView.startCountingDownWithTimeInterval(6.0)
			}
            self.swapNodeWithTouchNode(self.nodeLayer(location: currentNodeLocation))
        }
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        self._touchesEnded()
    }
}
