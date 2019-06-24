//
//  BModel.swift
//  SwCtDB
//
//  Created by 刘剑云 on 2018/10/17.
//  Copyright © 2018 ct. All rights reserved.
//

import Foundation

class BModel: NSObject {
    @objc var name = ""
    @objc var age = ""
    @objc var isnew = false
    
    override init() {
        super.init()
    }
    
    init(name: String, age: String, isnew: Bool) {
        super.init()
        self.name = name
        self.age = age
        self.isnew = isnew
    }
    
    override var description: String {
        return "\(name) \(age) \(isnew) "
    }
}
