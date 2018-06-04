//
//  ViewController.swift
//  SwCtDB
//
//  Created by 刘剑云 on 2018/6/1.
//  Copyright © 2018年 ct. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    @IBAction func createTable(_ sender: UIButton) {
        
    }
    
    @IBAction func dropTable(_ sender: UIButton) {
        
    }
    
    @IBAction func addData(_ sender: UIButton) {
        var datas: [AModel] = []
        for index in 0..<10 {
            datas.append(AModel.init(name: "name\(index)", age: index))
        }
        
        let db = SwCtDB.manager()
        print(db.dbPath())
        db.insert(datas)
    }
    
    @IBAction func cutData(_ sender: UIButton) {
        let db = SwCtDB.manager()
        print(db.dbPath())
        db.delete(AModel.self, cons: [db.con(db.id, .equal, 2)])
    }
    
    @IBAction func changeData(_ sender: UIButton) {
        let db = SwCtDB.manager()
        print(db.dbPath())
        db.update(AModel.self, sets: [db.set("name", "changeName")], cons: [db.con(db.id, .equal, 3)])
    }
    
    @IBAction func searchData(_ sender: UIButton) {
        let db = SwCtDB.manager()
        print(db.dbPath())
        let datas = db.select(AModel.self)
        
        print(datas)
    }
}
