import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif







/**
 简单封装网络请求工具-支持Liunx平台
 默认串行 - 即：每次只能执行一次请求，上一个请求完成之后才会执行下一个请求。
 
 PS: 该工具可用于Swift脚本运行
 */
class Network
{
//MARK: -
    
    /**
     Content-Type类型自定义
     */
    public static var contentType = "application/json"
    public static var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 13) AppleWebKit/618.11 (KHTML, like Gecko) Version/17.1.63 Safari/618.11"
    
    
    /**
     是否使用并发请求
     false：串行 - 默认
     true：并发
     */
    public static var isConcurrency = false
    
//MARK: -
    
    private static let semaphore = DispatchSemaphore(value: 0)
    private static func wait(){
        if isConcurrency{
            return
        }
        semaphore.wait()
    }
    
    private static func signal(){
        if isConcurrency{
            return
        }
        semaphore.signal()
    }
    
    
    
//MARK: -
    
    
    
    /**
     URLSession实现的网络请求功能
     请求方式：GET
     - url：请求URL
     - success：请求成功回调
     - fail：请求失败回调
     */
    public static func get(url:String,
             success:@escaping (_ resultData:Data?, _ statusCode:Int, _ request:URLRequest, _ response:URLResponse?) -> Void,
             fail:@escaping (_ error:Error, _ request:URLRequest) -> Void )
    {
        guard let url = URL(string: url) else{
            print("Invalid URL:\(url)")
            signal()
            return;
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        print("Method:\( String(describing:request.httpMethod) )")
        
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                fail(error, request)
            }else{
                let code = (response as! HTTPURLResponse).statusCode
                success(data,code,request,response)
            }
            
            signal()
        }
        task.resume()
        
        wait()
    }
    
    
    
    
    /**
     URLSession实现的网络请求功能
     请求方式：POST
     - url：请求URL
     - par：请求参数
     - success：请求成功回调
     - fail：请求失败回调
     */
    public static func post(url:String,
             par:[String:Any]?,
             success:@escaping (_ resultData:Data?, _ statusCode:Int, _ request:URLRequest, _ response:URLResponse?) -> Void,
             fail:@escaping (_ error:Error, _ request:URLRequest) -> Void )
    {
        guard let url = URL(string: url) else{
            print("Invalid URL:\(url)")
            signal()
            return;
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        // 添加Body参数
        if let dict = par {
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict){
                request.httpBody = jsonData
            }
        }
        
        print("Method:\( String(describing:request.httpMethod) )")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                fail(error, request)
            }else{
                let code = (response as! HTTPURLResponse).statusCode
                success(data,code,request,response)
            }
            
            signal()
        }
        task.resume()
        
        wait()
    }

}





//MARK: - Test


//Network.get(url: "https://cts-vapor-shulker.itunnel.cc.cd") { resultData, statusCode, request, response in
//    print("statusCode:\(statusCode)")
//    if let resultData {
//        print("resultData:\(resultData)")
//        
//        let result = String(data: resultData, encoding: .utf8) ?? ""
//        print("resultString:\(result)")
//    }
//} fail: { error, request in
//    
//}

