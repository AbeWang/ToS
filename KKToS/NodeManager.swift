//
//  NodeManager.swift
//  KKToS
//
//  Created by Abe on 2014/7/17.
//  Copyright (c) 2014 Abe Wang. All rights reserved.
//

import Foundation

class NodeManager {

    /* 建立 row x column 個 nodes */
    func createNodes(#rowCount: Int, columnCount:Int) -> NSMutableArray {
        var resultArray: NSMutableArray = NSMutableArray()
        for rowIndex in 0..<rowCount {
            var rowArray: NSMutableArray = NSMutableArray()
            for columnIndex in 0..<columnCount {
				let nodeTypeArray: [NodeLayerType] = [.RED, .BLUE, .YELLOW, .PURPLE, .GREEN, .PINK]
                let nodeLocation: NodeLocation = NodeLocation(row: rowIndex + 1, column: columnIndex + 1)
                let node: NodeLayer = NodeLayer(nodeType: nodeTypeArray[Int(arc4random() % 6)], nodeLocation: nodeLocation)
                rowArray.addObject(node)
            }
            resultArray.addObject(rowArray)
        }
        return resultArray
    }

}
