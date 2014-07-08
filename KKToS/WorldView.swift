//
//  WorldView.swift
//  KKToS
//
//  Created by Abe on 2014/7/8.
//  Copyright (c) 2014年 Abe Wang. All rights reserved.
//

import UIKit

class WorldView : UIView {
    var rowCount: Int = 5
    var columnCount: Int = 6
    let gridHeight: CGFloat = 50.0
    
    init(frame: CGRect, rowCount: Int, columnCount: Int) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.gridHeight = CGRectGetWidth(frame) / Double(columnCount)
        self.frame = CGRectMake(frame.origin.x, frame.origin.y, CGRectGetWidth(frame), gridHeight * Double(rowCount))
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        for var row = 0; row < rowCount; ++row {
            for var column = 0; column < columnCount; ++column {
                let pathRect: CGRect = CGRectMake(gridHeight * Double(column), gridHeight * Double(row), gridHeight, gridHeight)
                let path: UIBezierPath = UIBezierPath(rect: pathRect)
                if (column + row) % 2 == 0 {
                    UIColor(red: 0.133, green: 0.075, blue: 0.04, alpha: 1.0).set()
                }
                else {
                    UIColor(red: 0.259, green: 0.153, blue: 0.082, alpha: 1.0).set()
                }
                path.stroke()
                path.fill()
            }
        }
    }
}
