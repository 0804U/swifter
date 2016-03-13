//
//  Relfection.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public protocol DatabaseReflectionProtocol {
    
    var id: UInt64? { get }
    
    init()
}

public class DatabaseReflection: DatabaseReflectionProtocol {
    
    static var sharedDatabase: SQLite?
    
    public var id: UInt64? = nil
    
    required public init() { }
}

public extension DatabaseReflectionProtocol {
    
    public func schemeWithValuesMethod1() -> (String, [String: Any?]) {
        let reflections = _reflect(self)
        
        var fields = [String: Any?]()
        for index in 0.stride(to: reflections.count, by: 1) {
            let reflection = reflections[index]
            fields[reflection.0] = reflection.1.value
        }
        
        return (reflections.summary, fields)
    }
    
    public func schemeWithValuesMethod2() -> (String, [String: Any?]) {
        let mirror = Mirror(reflecting: self)
        
        var fields = [String: Any?]()
        for case let (label?, value) in mirror.children {
            fields[label] = value
        }
        
        return ("\(mirror.subjectType)", fields)
    }
    
    public func schemeWithValuesAsString() -> (String, [String: String?]) {
        let (name, fields) = schemeWithValuesMethod2()
        var map = [String: String?]()
        for (key, value) in fields {
            // TODO - Replace this by extending all supported types by a protocol.
            // Example: 'extenstion Int: DatabaseConvertible { convert() -> something ( not necessary String type ) }'
            if let intValue    = value as? Int    { map[key] = String(intValue) }
            if let int32Value  = value as? Int32  { map[key] = String(int32Value) }
            if let int64Value  = value as? Int64  { map[key] = String(int64Value) }
            if let doubleValue = value as? Double { map[key] = String(doubleValue) }
            if let stringValue = value as? String { map[key] = stringValue }
        }
        return (name, map)
    }
    
    public static func classInstanceWithSchemeMethod1() -> (Self, String, [String: Any?]) {
        let instance = Self()
        let (name, fields) = instance.schemeWithValuesMethod1()
        return (instance, name, fields)
    }
    
    public static func classInstanceWithSchemeMethod2() -> (Self, String, [String: Any?]) {
        let instance = Self()
        let (name, fields) = instance.schemeWithValuesMethod2()
        return (instance, name, fields)
    }
    
    static func find(id: UInt64) -> Self? {
        let (instance, _, _) = classInstanceWithSchemeMethod1()
        // TODO - make a query to DB
        return instance
    }
    
    public func insert() throws {
        guard let database = DatabaseReflection.sharedDatabase else {
            throw SQLiteError.OpenFailed("Database connection is not opened.")
        }
        let (name, fields) = schemeWithValuesAsString()
        let create = "CREATE TABLE IF NOT EXISTS \(name) (" + fields.keys.map { "\($0) TEXT" }.joinWithSeparator(", ")  + ");"
        try database.exec(create)
        // TODO - Replace this with the binding to avoid SQL injection.
        let ordered = fields.keys.reduce([(String, String)]()) { $0 + [($1, "\"\(fields[$1])\"")] }
        let names = ordered.map({ $0.0 }).joinWithSeparator(", ")
        let values = ordered.map({ $0.1 }).joinWithSeparator(", ")
        try database.exec("INSERT INTO \(name)(" + names + ") VALUES(" + values  + ");" )
    }
    
}