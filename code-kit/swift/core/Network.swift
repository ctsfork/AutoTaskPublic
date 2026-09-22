import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif





/**
 简单封装网络请求工具 - 支持Liunx平台(与具体的请求站点相关，比如请求Cloudflare托管的域名就会有请求错误问题)。
 默认串行 - 即：每次只能执行一次请求，上一个请求完成之后才会执行下一个请求。
 
 PS: 该工具可用于Swift脚本运行
 
 ⚠️警告⚠️：
 1. 对URLSession的封装虽然支持在Linux平台上运行，但是由于URLSession在Linux平台的底层是使用的是libcurl，它本身就有一些bug，所以非必要在Linux上不要使用URLSession。
 2. 虽然Linux上的URLSession有些问题但是使用URLSession来请求国内的站点一般是没有问题，只是在请求境外的站点，比如Cloudflare托管的域名时，使用URLSession请求就有问题，这是在Linux上就不要使用URLSession。
     ⚠️：造成这种问题的原因一般是libcurl在处理SSL不符合形如Cloudflare站点的要求而被拒绝请求。
 3. 如果在Linux 上需要请求境外站点时，不要推荐使用URLSession，推荐使用AsyncHTTPClient进行网络请求。
 4. ⚠️注意：并不是所有的境外的网站在Linux 上使用URLSession请求时都有问题，使用时可以具体选择是否使用URLSession。
 5. 如果是在macOS上使用URLSession就完全没有这个问题。
 6. 为什么总是在Linux上纠结使用URLSession就是因为它式样简单不会增加可执行程序的体积，并且用于捡的Swift脚本中运行。而AsyncHTTPClient虽然很好，但是它比较大，并且不适合在Swift脚本中使用。
 
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
     Linux平台URLSession的使用警告
     */
    public static func linuxWarning(){
#if os(Linux)
    print("⚠️⚠️警告⚠️⚠️：当前是在Linux平台上运行，URLSession要慎用，如果强制使用URLSession则需要请求的域名能被URLSession正确支持。")
#endif
    }
    
    
    
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
        linuxWarning()
        
        guard let url = URL(string: url) else{
            print("Invalid URL:\(url)")
            signal()
            return;
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        
        
#if canImport(FoundationNetworking)
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: cfg)
#else
        let session = URLSession.shared
#endif
        
        
        
        let task = session.dataTask(with: request) { (data, response, error) in
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
        linuxWarning()
        
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
        
        
        
#if canImport(FoundationNetworking)
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        
        let session = URLSession(configuration: cfg)
#else
        let session = URLSession.shared
#endif
        

        
        let task = session.dataTask(with: request) { (data, response, error) in
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
//
////let testURL = "https://cts-vapor-shulker.itunnel.cc.cd"
////let testURL = "https://www.baidu.com"
//let testURL = "https://github.com"
//
//Network.get(url: testURL ) { resultData, statusCode, request, response in
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

