//
//  NodeManager.swift
//  KKToS
//
//  Created by Abe on 2014/7/17.
//  Copyright (c) 2014 Abe Wang. All rights reserved.
//

import Foundation

class NodeManager {
    
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
}
