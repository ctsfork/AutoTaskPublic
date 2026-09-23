//
//  File.swift
//  
//
//  Created by kimi on 2026/9/23.
//

import Foundation


/**
 一些常用日期处理工具
 */
struct DateTool{
    /**
     获取当前时间 - 使用中国时区
     */
    public static func currentDate() -> String{
        let dateFormatter = DateFormatter()
        //固定为中国时区
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss SSS"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = dateFormatter.string(from: Date())
        return dateStr
    }
    
}
