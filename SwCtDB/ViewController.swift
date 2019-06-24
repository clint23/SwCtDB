//
//  ViewController.swift
//  SwCtDB
//
//  Created by 刘剑云 on 2018/6/1.
//  Copyright © 2018年 ct. All rights reserved.
//

import UIKit


enum CEnum {
    case normal
    case other
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    
    
    @IBAction func createTable(_ sender: UIButton) {
//        var cmodel = CModel.init()
//        
//        var array = [1, 2, 3, 4, 5]
//        var arrayPtr = UnsafeMutableBufferPointer<Int>(start: &array, count: array.count)
//        // baseAddress 是第一个元素的指针
//        var basePtr = arrayPtr.baseAddress
//        basePtr?.pointee = 10
//        print(array)
    }
    
    @IBAction func dropTable(_ sender: UIButton) {
        
    }
    
    @IBAction func addData(_ sender: UIButton) {
        var data: [BModel] = []
        for index in 0..<1000 {
            data.append(BModel.init(name: "name\(index)", age: "age \(index)", isnew: false))
        }
        let db = SwCtDB.manager()
        print(db.dbPath())
        db.insert(data)
        
//        var datas: [AModel] = []
//        for index in 0..<10 {
//            datas.append(AModel.init(name: "name\(index)", age: index))
//        }
//
//        let db = SwCtDB.manager()
//        print(db.dbPath())
//        db.insert(datas)
    }
    
    @IBAction func cutData(_ sender: UIButton) {
        let db = SwCtDB.manager()
        print(db.dbPath())
        db.delete(AModel.self, cons: [con(SwCtDB.id, .equal, 2)])
    }
    
    @IBAction func changeData(_ sender: UIButton) {
        let db = SwCtDB.manager()
        print(db.dbPath())
        db.update(BModel.self, sets: [set("isnew", true)])
        print(db.select(BModel.self))
    }
    
    @IBAction func searchData(_ sender: UIButton) {
        let db = SwCtDB.manager()
        print(db.dbPath())
        let datas = db.select(BModel.self)
        print(datas)
    }
}

