//
//  NSObject+DBExtension.swift
//  SwCtDB
//
//  Created by 刘剑云 on 2018/10/16.
//  Copyright © 2018 ct. All rights reserved.
//

import Foundation

struct DBAssociatedKey {
    static var iD: UInt8 = 0
}

public extension NSObject {
    public var iD: Int {
        get { return (objc_getAssociatedObject(self, &DBAssociatedKey.iD) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &DBAssociatedKey.iD, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
