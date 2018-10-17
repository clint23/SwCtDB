//
//  AModel.swift
//  SwCtDB
//
//  Created by 刘剑云 on 2018/6/1.
//  Copyright © 2018年 ct. All rights reserved.
//

import UIKit

class AModel: NSObject {
    @objc var name = ""
    @objc var age = 0
    
    init(name: String, age: Int) {
        super.init()
        self.name = name
        self.age = age
    }

//    override init() {
//        super.init()
//    }
    
    override var description: String {
        return "\(name) \(age) \(iD)"
    }
}
