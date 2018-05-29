//
//  SQLiteForData.swift
//  Alexa iOS App
//
//  Created by God on 2017/6/26.
//  Copyright © 2017 Bling. All rights reserved.
//

import Foundation

class SQLiteForData {
    
    var db :OpaquePointer? = nil
    let sqlitePath :String
    
    init?(path :String) {
        sqlitePath = path
        db = self.openDatabase(sqlitePath)
        
        if db == nil {
            return nil
        }
    }
    
    // MARK - connect database
    func openDatabase(_ path :String) -> OpaquePointer? {
        var connectdb: OpaquePointer? = nil
        if sqlite3_open(path, &connectdb) == SQLITE_OK {
            print("Successfully opened database \(path)")
            return connectdb!
        } else {
            print("Unable to open database.")
            return nil
        }
    }
    
    // MARK - create table
    func createTable(_ tableName :String, columnsInfo :[String]) -> Bool {
        let sql = "create table if not exists \(tableName) "
            + "(\(columnsInfo.joined(separator: ",")))"
        
        print(sql)
        
        if sqlite3_exec(self.db, sql.cString(using: String.Encoding.utf8), nil, nil, nil) == SQLITE_OK {
            print("[SQLite] create table ok")
            return true
        }
        
        print("[SQLite] create table error")
        return false
    }
    
    // MARK - select data
    func select(_ tableName: String, cond: String?, order: String?) -> OpaquePointer {
        var statement: OpaquePointer? = nil
        var sql = "select * from \(tableName)"
        
        if let condition = cond {
            sql += " where \(condition)"
        }
        if let orderBy = order {
            sql += " order by \(orderBy)"
        }
        
        print(sql)
        
        sqlite3_prepare_v2(self.db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
        return statement!
    }
    
    // MARK - insert data
    func insert(_ tableName :String, rowInfo :[String:String]) -> Bool {
        var statement :OpaquePointer? = nil
        let sql = "insert into \(tableName) "
            + "(\(rowInfo.keys.joined(separator: ","))) "
            + "values (\(rowInfo.values.joined(separator: ",")))"
        
        print(sql)
        
        if sqlite3_prepare_v2(self.db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("[SQLite] insert data ok")
                return true
            }
            sqlite3_finalize(statement)
        }
        
        print("[SQLite] insert data error")
        return false
    }
    
    // MARK - update data
    func update(_ tableName :String, cond :String?, rowInfo :[String:String]) -> Bool {
        var statement :OpaquePointer? = nil
        var sql = "update \(tableName) set "
        
        // row info
        var info :[String] = []
        for (k, v) in rowInfo {
            info.append("\(k) = \(v)")
        }
        sql += info.joined(separator: ",")
        
        // condition
        if let condition = cond {
            sql += " where \(condition)"
        }
        
        print(sql)
        
        if sqlite3_prepare_v2(self.db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("[SQLite] update data ok")
                return true
            }
            sqlite3_finalize(statement)
        }
        
        print("[SQLite] update data error")
        return false
    }
    
    // MARK - delete data
    func delete(_ tableName :String, cond :String?) -> Bool {
        var statement :OpaquePointer? = nil
        var sql = "delete from \(tableName)"
        
        // condition
        if let condition = cond {
            sql += " where \(condition)"
        }
        
        print(sql)
        
        if sqlite3_prepare_v2(self.db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("[SQLite] delete data ok")
                return true
            }
            sqlite3_finalize(statement)
        }
        
        print("[SQLite] delete data error")
        return false
    }
}
