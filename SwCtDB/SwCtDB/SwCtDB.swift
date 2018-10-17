//
//  SwCtDB.swift
//  SwCtDB
//
//  Created by 刘剑云 on 2018/6/1.
//  Copyright © 2018年 ct. All rights reserved.
//

import UIKit
import SQLite3

/// 支持的列类型
///
/// - text: 字符型
/// - real: 浮点型
/// - integer: 整型
/// - blob: 二进制型
public enum ColumnType: Int {
    case text = 0
    case real = 1
    case integer = 2
    case blob = 3
}

public enum ConType: String {
    case big = ">"
    case equal = "="
    case small = "<"
    case bigE = ">="
    case smallE = "<="
    case notE = "!="
}

public enum OrderType: String {
    case ase = "asc"
    case desc = "desc"
}

/// 条件表达式
///
/// - Parameters:
///   - key: 键
///   - type: 条件类型
///   - value: 值
/// - Returns: 条件表达式字符串
public func con(_ key: String, _ type: ConType, _ value: Any) -> String {
    var result = "\(key) \(type.rawValue) \(value)";
    if (value is String) || (value is NSString) {
        result = "\(key) \(type.rawValue) '\(value)'"
    }
    return result
}

/// 设置表达式
///
/// - Parameters:
///   - key: 键
///   - value: 值
/// - Returns: 设置表达式字符串
public func set(_ key: String, _ value: Any) -> String {
    var result = "\(key) = \(value)";
    if (value is String) || (value is NSString) {
        result = "\(key) = '\(value)'"
    }
    return result
}

/// 排序表达式
///
/// - Parameters:
///   - key: 键
///   - type: 排序类型
/// - Returns: 排序表达式字符串
public func ord(_ key: String, _ type: OrderType) -> String {
    return "\(key) \(type.rawValue)"
}

// 以模型化为核心操作sqlite，表对应数据模型，在执行静态初始化方法后，将自动查询所有的表并进行表的更新，在对应数据模型类增加属性，将自动添加列并给定默认值
/// 在数据模型类删减属性则自动删减表对应类，对于支持的数据类型，目前只支持Int，Float，Double，String类型，请以这些类型为存储标准，对于非支持类型，数据表
/// 会创建对应列但会置为null
/// 无需进行表创建，删除操作，在执行增删改查相关操作时会自动创建数据表，在数据模型类删除后将自动删除数据表
/// 创建的模型类需要继承于CtTable
public class SwCtDB: NSObject {
    private static let instance = SwCtDB()
    public static let id = "_id"
    private static let tableSign = "tableSign"
    private let tmpTableName = "tmp"
    private var tableColumns: [String : [String : ColumnType]] = [:]
    private var db = OpaquePointer.init(bitPattern: 0)
    
    /// 静态初始化方法，这里将进行列表更新处理操作，自动删除或增加表列，自动删除多余的表，在表迁移操作时要特别注意
    ///
    /// - Returns: 单例对象
    public static func manager() -> SwCtDB{
        instance.tableColumns.removeAll()
        let tableNames = instance.exportTableNames()
        tableNames.forEach { (tableName) in
            if let cla = NSClassFromString(cName(tableName)) {
                instance.inspectColumn(cla)
                instance.tableColumns[tableName] = instance.exportPropertiesAndTypes(cla)
            }else {
                instance.dropTable(tableName)
            }
        }
        return instance
    }
    
    override public func copy() -> Any {
        return self
    }
    
    override public func mutableCopy() -> Any {
        return self
    }
    
    public func dbPath() -> String {
        let document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        return (document! as NSString).appendingPathComponent(Bundle.main.bundleIdentifier! + ".db")
    }
    
    private func open() -> Bool {
        return sqlite3_open(dbPath(), &db) == SQLITE_OK
    }
}


// MARK: - 表操作相关
public extension SwCtDB {
    
    /// 创建数据表，该函数用于内部调用，在进行增删改查等操作时会自动执行
    ///
    /// - Parameter cla: 类
    /// - Returns: 是否成功创建
    @discardableResult private func createTable(_ cla: AnyClass) -> Bool {
        var result = true
        if !tableColumns.keys.contains(tName(cla)) {
            let properties = self.exportProperties(cla)
            let sql = "create table if not exists \(tName(cla)) (\(SwCtDB.id) integer primary key autoincrement, \((properties as NSArray).componentsJoined(by: ", ")))"
            result = (sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK)
            if result {
                tableColumns[tName(cla)] = exportPropertiesAndTypes(cla)
            }
        }
        return result
    }
    
    /// 删除表
    ///
    /// - Parameter table: 表名
    /// - Returns: 是否成功删除表
    @discardableResult public func dropTable(_ table: String) -> Bool {
        let sql = "drop table if exists \(table)"
        return (sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK)
    }
    
    /// 拷贝表
    ///
    /// - Parameters:
    ///   - from: 待拷贝的表的表名
    ///   - columns: 列名列表
    ///   - to: 要拷贝为的表名
    /// - Returns: 是否成功拷贝表
    @discardableResult public func copyTable(_ from: String, columns: [String], to: String) -> Bool {
        let sql = "create table \(to) as select \((columns as NSArray).componentsJoined(by: ", ")) from \(from)"
        
        return (sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK)
    }
    
    /// 重命名表
    ///
    /// - Parameters:
    ///   - from: 待重命名的表名
    ///   - to: 新命名
    /// - Returns: 是否成功重命名表
    @discardableResult public func renameTable(_ from: String, to: String) -> Bool {
        let sql = "alter table \(from) rename to \(to)"
        return (sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK)
    }
}


// MARK: - 数据操作相关
extension SwCtDB {
    /// 插入数据，这里要插入的数据必须是同一种类型，且继承于CtTable
    ///
    /// - Parameter datas: 待插入的数据源
    /// - Returns: 是否插入成功
    @discardableResult public func insert(_ datas: [NSObject]) -> Bool {
        var result = true
        if datas.count > 0 {
            if createTable(datas.first!.classForCoder) {
                let columns = exportTableColumns(datas.first!.classForCoder)
                let each = tableColumns[tName(datas.first!.classForCoder)]
                var places = "?"
                
                var texts: [String : Int] = [:]
                var reals: [String : Int] = [:]
                var integets: [String : Int] = [:]
                var blobs: [String : Int] = [:]
                
                each?.forEach({ (key, type) in
                    switch type {
                    case .text:
                        texts[key] = columns.index(of: key)! + 1
                    case .real:
                        reals[key] = columns.index(of: key)! + 1
                    case .integer:
                        integets[key] = columns.index(of: key)! + 1
                    default:
                        blobs[key] = columns.index(of: key)! + 1
                    }
                    places += ",?"
                })
                
                if sqlite3_exec(db, "begin", nil, nil, nil) == SQLITE_OK {
                    var stmt = OpaquePointer.init(bitPattern: 0)
                    let sql = "insert into \(tName(datas.first!.classForCoder)) values (\(places))"
                    sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
                    datas.forEach { (data) in
                        texts.forEach({ (arg) in
                            let (key, value) = arg
                            let textValue = (data.value(forKey: key) as! NSString)
                            sqlite3_bind_text(stmt, CInt(value), textValue.utf8String, -1, nil)
                        })
                        reals.forEach({ (arg) in
                            let (key, value) = arg
                            sqlite3_bind_double(stmt, Int32(value), data.value(forKey: key) as! Double)
                        })
                        integets.forEach({ (arg) in
                            let (key, value) = arg
                            sqlite3_bind_int(stmt, Int32(value), data.value(forKey: key) as! Int32)
                        })
                        sqlite3_step(stmt)
                        sqlite3_reset(stmt)
                    }
                    sqlite3_finalize(stmt)
                    result = (sqlite3_exec(db, "commit", nil, nil, nil) == SQLITE_OK)
                    
                }else {
                    result = false
                }
            }
            
        }
        return result
    }
    
    /// 删除数据
    ///
    /// - Parameters:
    ///   - cla: 类
    ///   - cons: 条件表达式组
    /// - Returns: 是否删除成功
    @discardableResult public func delete(_ cla: AnyClass, cons: [String]? = nil) -> Bool {
        var result = false
        if createTable(cla) {
            var sql = "delete from \(tName(cla))";
            if cons != nil {
                if cons!.count > 0 {
                    sql.append(" where \((cons! as NSArray).componentsJoined(by: " and "))")
                }
            }
            result = (sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK)
        }
        return result
    }
    
    /// 更新数据
    ///
    /// - Parameters:
    ///   - cla: 类
    ///   - sets: 设置表达式组
    ///   - cons: 条件表达式组
    /// - Returns: 是否更新成功
    @discardableResult public func update(_ cla: AnyClass,  sets: [String], cons: [String]? = nil) -> Bool {
        var result = false
        if createTable(cla) {
            var sql = "update \(tName(cla))";
            if sets.count > 0 {
                sql.append(" set \((sets as NSArray).componentsJoined(by: ", "))")
            }
            if cons != nil {
                if cons!.count > 0 {
                    sql.append(" where \((cons! as NSArray).componentsJoined(by: " and "))")
                }
            }
            result = (sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK)
        }
        return result
    }
    
    /// 查询数据，数据会自动模型化
    ///
    /// - Parameters:
    ///   - cla: 类
    ///   - keys: 要查询的键
    ///   - cons: 条件表达式组
    ///   - ords: 排序表达式组
    /// - Returns: 查询出来的数据
    @discardableResult public func select<T: NSObject>(_ cla: T.Type, keys: [String]? = nil, cons: [String]? = nil, ords: [String]? = nil) -> [T] {
        var datas: [T] = []
        if createTable(cla) {
            var key = "*"
            if keys != nil {
                key = (keys! as NSArray).componentsJoined(by: ", ")
            }
            var sql = "select \(key) from \(tName(cla))"
            if cons != nil {
                if cons!.count > 0 {
                    sql.append(" where \((cons! as NSArray).componentsJoined(by: " and "))")
                }
            }
            if ords != nil {
                if ords!.count > 0 {
                    sql.append(" order by \((ords! as NSArray).componentsJoined(by: ", "))")
                }
            }
            var stmt = OpaquePointer.init(bitPattern: 0)
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                var each = tableColumns[tName(cla)]
                var indexs: [String : CInt] = [:]
                while (sqlite3_step(stmt) == SQLITE_ROW) {
                    let tmp = T.init()
                    if indexs.count == 0 {
                        let columnNum = sqlite3_column_count(stmt)
                        for index in 0..<columnNum {
                            indexs[String.init(cString: sqlite3_column_name(stmt, index))] = index
                        }
                    }
                    let columns = indexs.keys.filter{ $0 != "_id" }
                    columns.enumerated().forEach { (offset, element) in
                        let type = each![element]!
                        switch type {
                        case .text:
                            tmp.setValue(String.init(cString: sqlite3_column_text(stmt, indexs[element]!)), forKey: element)
                        case .real:
                            tmp.setValue(sqlite3_column_double(stmt, indexs[element]!), forKey: element)
                        case .integer:
                            tmp.setValue(Int(sqlite3_column_int(stmt, indexs[element]!)), forKey: element)
                        default:
                            break
                        }
                    }
                    tmp.iD = Int(sqlite3_column_int(stmt, indexs["_id"]!))
                    datas.append(tmp)
                }
            }
            
        }
        return datas
    }
}

// MARK: - 表基准数据相关
public extension SwCtDB {
    /// 获取所有表名
    ///
    /// - Returns: 表名列表
    public func exportTableNames() -> [String] {
        var tableNames: [String] = []
        if self.open() {
            let sql = "select name from sqlite_master where name != 'sqlite_sequence'";
            
            var stmt = OpaquePointer.init(bitPattern: 0)
            let prepare_result = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
            if prepare_result == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    tableNames.append(String(cString: sqlite3_column_text(stmt, 0)))
                }
            }
        }
        return tableNames
    }
    
    /// 获取某表对应的所有列名
    ///
    /// - Parameter cla: 类
    /// - Returns: 列名列表
    public func exportTableColumns(_ cla: AnyClass) -> [String] {
        var columns: [String] = []
        if self.open() {
            let sql = "PRAGMA table_info([\(tName(cla))])"
            var stmt = OpaquePointer.init(bitPattern: 0)
            let prepare_result = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
            if prepare_result == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    columns.append(String(cString: sqlite3_column_text(stmt, 1)))
                }
            }
        }
        return columns
    }
    
    /// 校验并修正表，如果表与类无法对应，将自动删除或增加列
    ///
    /// - Parameter cla: 待校验的表
    private func inspectColumn(_ cla: AnyClass) {
        let columns = exportTableColumns(cla)
        var properties = exportProperties(cla)
        var propertiesAndTypes = exportPropertiesAndTypes(cla)
        properties.append(SwCtDB.id)
        
        let addColumns = (properties as NSArray).filtered(using: NSPredicate.init(format: "NOT (SELF IN %@)", columns)) as! [String]
        addColumns.forEach { (column) in
            let type = propertiesAndTypes[column]
            var sql = "alter table \(tName(cla)) add column \(column)"
            switch type! {
            case .text:
                sql = "alter table \(tName(cla)) add column \(column) default ''"
            case .real:
                sql = "alter table \(tName(cla)) add column \(column) default 0.0"
            case .integer:
                sql = "alter table \(tName(cla)) add column \(column) default 0"
            default:
                break
            }
            sqlite3_exec(db, sql, nil, nil, nil)
        }
        
        let cutColumns = (columns as NSArray).filtered(using: NSPredicate.init(format: "NOT (SELF IN %@)", properties)) as! [String]
        if cutColumns.count > 0 {
            copyTable(tName(cla), columns: properties, to: tmpTableName)
            dropTable(tName(cla))
            renameTable(tmpTableName, to: tName(cla))
        }
    }
    
    private func tName(_ cla: AnyClass) -> String {
        return cla.description().replacingOccurrences(of: ".", with: SwCtDB.tableSign)
    }
    
    private static func cName(_ name: String) -> String {
        return name.replacingOccurrences(of: SwCtDB.tableSign, with: ".")
    }
}

// MARK: - 反射相关
extension SwCtDB {
    /// 获取某类所有的属性
    ///
    /// - Parameter cla: 类
    /// - Returns: 类的属性列表
    func exportProperties(_ cla: AnyClass) -> [String] {
        var count: u_int = 0
        let properties = class_copyPropertyList(cla, &count)
        var keys: [String] = []
        for index in 0..<count {
            keys.append(String(utf8String: property_getName(properties![Int(index)]))!)
        }
        let except = ["superclass", "description", "debugDescription", "hash"]
        return (keys as NSArray).filtered(using: NSPredicate.init(format: "NOT (SELF IN %@)", except)) as! [String]
    }
    
    /// 获取某类的所有属性和属性类型
    ///
    /// - Parameter cla: 类
    /// - Returns: 类的属性及属性类型列表
    func exportPropertiesAndTypes(_ cla: AnyClass) -> [String : ColumnType] {
        var count: u_int = 0
        let properties = class_copyPropertyList(cla, &count)
        let except = ["superclass", "description", "debugDescription", "hash"]
        var columns: [String : ColumnType] = [:]
        for index in 0..<count {
            let key = String(utf8String: property_getName(properties![Int(index)]))!
            if !except.contains(key) {
                columns[key] = transToColumnType(String(utf8String: property_getAttributes(properties![Int(index)])!)!)
            }
        }
        return columns
    }
    
    /// 类型转换
    ///
    /// - Parameter base: 属性类型值
    /// - Returns: 转换后的类型
    func transToColumnType(_ base: String) -> ColumnType {
        var type = ColumnType.blob
        let baseTypes = ["T@\"NSString\"", "Td", "Tf", "Tq", "TB"]
        let transTypes: [ColumnType] = [.text, .real, .real, .integer, .integer]
        for index in 0..<baseTypes.count {
            if base.hasPrefix(baseTypes[index]) {
                type = transTypes[index]
                break
            }
        }
        return type
    }
}

