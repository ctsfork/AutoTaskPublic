//
//  File.swift
//  
//
//  Created by kimi on 2026/9/22.
//

import Foundation





/**
 环境变量管理器：用于处理用户定义的环境变量

 
 ✅✅环境变量命名规则:
 1. 环境变量只支持全小写或者全大写的变量名。
 2. 受支持的环境变量可以解析它的全大小写模式。
    例如：变量port=8080，程序会依次尝试解析port，PORT的值，但是不会解析Port.
 */
class EnvManager{
    static let shared:EnvManager = .init()
        
    init(){
//        print("environment:\(ProcessInfo.processInfo.environment)")
    }
    
}


extension EnvManager{
    
//MARK: - 通用的环境变量值获取
    /**
     根据环境变量名称直接从环境变量获取其值，环境变量名称 - 同时支持全大/小写和原始输入值.
     比如：
        输入：名称为Int的环境变量，它会依次取获取名称为：Int,INT,int的环境变量值，并且只要匹配到了一个立即返回
     
     获取的值为String？，如果需要其它类型时就需要从String类型转换
     */
    func get(_ name: String) -> String?{
        let lowerName = name.lowercased()
        let upperName = name.uppercased()
        
        /**
         获取环境变量值的两种方案：
         1. Environment.get("EnvName") //Vapor
         2. ProcessInfo.processInfo.environment["EnvName"]
         */
        if let value = ProcessInfo.processInfo.environment[name]{
            return value
        }
        if let value = ProcessInfo.processInfo.environment[upperName]{
            return value
        }
        if let value = ProcessInfo.processInfo.environment[lowerName]{
            return value
        }
       
        return nil
    }

}




extension EnvManager{
//MARK: - 获取并转换成指定的数据类型
    
    /**
     获取String类型的环境变量值
     */
    func getString(name:String) -> String?{
        guard let string = get(name) else{
            return nil
        }
        return string
    }
    
    
    /**
     获取Bool类型的环境变量值。
     注意：除了解析正确的false，true值，还会解析：数字0 = false，数字非0 = true
     */
    func getBool(name:String) -> Bool?{
        guard let string = get(name) else{
            return nil
        }
        guard let value = Bool(string) else {
            if let value = Int(string){
                if value == 0 {
                    return false
                }else{
                    return true
                }
            }
            return nil
        }
        return value
    }
    
    /**
     获取Int类型的环境变量
     */
    func getInt(name:String) -> Int?{
        guard let string = get(name) else{
            return nil
        }
        guard let value = Int(string) else {
            return nil
        }
        return value
    }
    
    /**
     获取UInt类型的环境变量
     */
    func getUInt(name:String) -> UInt?{
        guard let string = get(name) else{
            return nil
        }
        guard let value = UInt(string) else {
            return nil
        }
        return value
    }
    
    /**
     获取Float类型的环境变量
     */
    func getFloat(name:String) -> Float?{
        guard let string = get(name) else{
            return nil
        }
        guard let value = Float(string) else {
            return nil
        }
        return value
    }
    
    /**
     获取Double类型的环境变量
     */
    func getDouble(name:String) -> Double?{
        guard let string = get(name) else{
            return nil
        }
        guard let value = Double(string) else {
            return nil
        }
        return value
    }
    
    
    
    /**
     获取JSONObject Any类型的环境变量 - 对应的环境变量值应该是一个JSON的格式的字符串。
     */
    func getJSONObject(name:String) -> Any?{
        guard let string = get(name) else{
            return nil
        }
        guard let data = string.data(using: .utf8) else{
            return nil
        }
        guard let josn = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        return josn
    }
    
    
    /**
     获取[String:Any]格式的字典类型的环境变量 - 对应的环境变量值应该是一个JSON的格式的字符串。
     */
    func getDictAny(name:String) -> [String:Any]?{
        guard let json = getJSONObject(name: name) else{
            return nil
        }
        //采用Any是为了清除解包nil空值
        guard let dict = json as? [String:Any?] else {
            return nil
        }
        var tmpDict:[String:Any] = [:]
        for (k,v) in dict {
            tmpDict[k] = v
        }
        return tmpDict
    }
    
    
    /**
     获取[String:String]格式的字典类型的环境变量 - 对应的环境变量值应该是一个JSON的格式的字符串。
     */
    func getDictString(name:String) -> [String:String]?{
        guard let json = getJSONObject(name: name) else{
            return nil
        }
        //采用Any是为了清除解包nil空值
        guard let dict = json as? [String:String?] else {
            return nil
        }
        var tmpDict:[String:String] = [:]
        for (k,v) in dict {
            tmpDict[k] = v
        }
        return tmpDict
    }
    
    
    /**
     获取[String]格式的数组类型的环境变量 - 对应的环境变量值应该是一个JSON的格式的字符串。
     */
    func getArrayString(name:String) -> [String]?{
        guard let json = getJSONObject(name: name) else{
            return nil
        }
        //采用Any是为了清除解包nil空值
        guard let list = json as? [String?] else {
            return nil
        }
        var tmp:[String] = []
        for item in list {
            if let item {
                tmp.append(item)
            }
        }
        return tmp
    }
    
    /**
     获取[Any]格式的数组类型的环境变量 - 对应的环境变量值应该是一个JSON的格式的字符串。
     */
    func getArrayAny(name:String) -> [Any]?{
        guard let json = getJSONObject(name: name) else{
            return nil
        }
        //采用Any是为了清除解包nil空值
        guard let list = json as? [Any?] else {
            return nil
        }
        var tmp:[Any] = []
        for item in list {
            if let item {
                tmp.append(item)
            }
        }
        return tmp
    }
    
    
    
}
