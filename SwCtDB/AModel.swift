//
//  AModel.swift
//  SwCtDB
//
//  Created by 刘剑云 on 2018/6/1.
//  Copyright © 2018年 ct. All rights reserved.
//

import UIKit

class AModel: CtTable {
    var name = ""
    var age = 0
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    required init() {}

    override var description: String {
        return "\(name) \(age)"
    }
}
