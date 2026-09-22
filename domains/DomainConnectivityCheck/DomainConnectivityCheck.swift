import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif





/**
 外部引用文件：
 - Network.swift：网络请求
 - PushBark.swift：推送通知
 */

@main
struct DomainConnectivityCheck{
    
    public static func main(){
        print("检查站点能否正常访问...")
        
        _ = DomainCheck()
    }
}




class DomainCheck{
    /**
     是否打印响应数据，包括：状态码，request，response
     */
    public static var isLog = false
    
    let ulrs = [
        "https://cts-vapor-shulker.itunnel.cc.cd/health",
        "https://ctsserver-shulker.itunnel.cc.cd/health"
    ]
    
    var msg:String = ""
    
    init() {
        msg = ""
        start()
        push()
        
    }
    
    
    private func check(url:String){
        Network.get(url: url ) { resultData, statusCode, request, response in
            print("statusCode:\(statusCode)")
            
            if Self.isLog {
                print("request:\(String(describing:request))")
                print("response:\(String(describing:response))")
                print("resultData:\(String(describing:resultData))")
            }

            
            if let resultData, let str = String(data: resultData, encoding: .utf8) {
                if Self.isLog {
                    print("resultString:\( str ))")
                }
            }

            /**
             200：响应成功
             403：GitHub Action中访问Cloudflare托管的站点，会出现Just a moment...
             // && statusCode != 403
             */
            if statusCode != 200  {
//                self.msg += "站点:\(url) 无法访问" + "\n"
                self.msg += "站点:\(url) 状态码非200" + "\n"
            }
        } fail: { error, request in
//            self.msg += "站点:\(url) 测试失败" + "\n"
            self.msg += "站点:\(url) 无法访问" + "\n"
        }
    }
    
    
    func start(){
        for url in ulrs {
            print("校验:\(url)")
            check(url: url)
        }
        print("\n")
    }
    
    
    func push(){
        if msg.isEmpty{
            print("✅✅站点访问正常✅✅")
            return;
        }
        
        let body = "\n" + msg + "\n\n检查时间：\(currentDate())"
        
        let title = "❌Shulker.in❌ - 有服务器出现了宕机"
        let subTitle = "CTSServer服务无法访问"
        let group = "CTSServer"
        
        
        print("\(title)\n\(subTitle)\(body)")
        
        print("推送通知:")
        
        
        //获取环境变量
        PushBark_Github.setupEnvironment()
        
        PushBark_Github.bark_send(title: title, subtitle: subTitle, body: body, group: group)
        PushBark_Github.serverChan_send(title: title, short:subTitle, desp: body, tags:group)
        PushBark_Github.pushdeer_send(text: title , desp: body, type:"markdown")
    }
    
    
    /**
     获取当前时间 - 使用中国时区
     */
    private func currentDate() -> String{
        let dateFormatter = DateFormatter()
        //固定为中国时区
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss SSS"
        let dateStr = dateFormatter.string(from: Date())
        return dateStr
    }
}
