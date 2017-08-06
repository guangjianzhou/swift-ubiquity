//
//  SelectionStatus.swift
//  Ubiquity
//
//  Created by sagesse on 07/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class SelectionStatus {
    
    init(asset: Asset, no: Int = 1) {
        self.asset = asset
        self.no = no
    }
    
    var no: Int 
    var asset: Asset
}
