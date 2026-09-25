import Foundation




/**
 功能：
DNSHE站点域名延期
 
 
 Github版:
 必须配置环境变量，并且需用通过setupEnvironment()方法获取并配置环境变量数据
 
 
 外部引用文件：
 - NetworkQueue.swift：网络请求
 - PushBark.swift：推送通知
 */




@main
struct DnsheDomainRenewal_Github{
    private static var domains:[RequestDomainsItem] = []
    
    public static func main(){
        print("DNSHE站点免费域名续期......")
        
        setupEnvironment()
        
        let renewal = DomainRenewal(domains: domains)
        renewal.start()
        
    }
    
    /**
     读取环境变量中的配置信息 - 使用Github版时必须先执行这个方法
     */
    private static func setupEnvironment(){
        print("从环境变量中读取配置......")
        
        if let DNSHEDomain_Domains:[RequestDomainsItem] = EnvManager.shared.getJSONDecoder(name: "DNSHEDomain_Domains") {
            self.domains = DNSHEDomain_Domains
        }else{
            print("❌DnsheDomainRenewal Environment - DNSHEDomain_Domains❌：需要延期的DNSHE API Key相关信息获取失败。")
        }

    }
}



/**
 DNSHE域名延期
 */
private class DomainRenewal{
    // DNSHE域名延期请求URL
    private var BaseURL = "https://api005.dnshe.com/index.php"
    
    // 获取所有域名列表请求URL
    private let listURL:String
    
    // 延期请求URL
    private let renewalURL:String
    
    
    /**
     需要延期域名的API配置信息列表
     */
    private var domains:[RequestDomainsItem] = [

    ]
    
    
    /**
     最终需要向用户推送的消息
     key: 对应配置中每个domain的用户信息
     value: 具体的提示消息
     */
    private var msgDict:[String:String] = [:]
    
    
    
    init(domains:[RequestDomainsItem]?) {
        listURL = self.BaseURL + "?m=domain_hub&endpoint=subdomains&action=list"
        renewalURL = self.BaseURL + "?m=domain_hub&endpoint=subdomains&action=renew"
        
        
        if let domains, domains.count > 0 {
            self.domains = domains
            print("当前使用的是环境变量中的数据......")
        }
        
    }
    

    
    
    func start(){
        //设置为串行，并且等待可能存在的操作完成
        NetworkQueue.isConcurrency = false
        NetworkQueue.waitUntilAllOperationsAreFinished()
        
        for item in domains{
            print("✅✅开始✅✅")
            
            getDomainList(userItem: item)
            
            //等待
            NetworkQueue.waitUntilAllOperationsAreFinished()
            
            print("✅✅完成✅✅\n\n")
        }
        
        
        //推送通知信息
        push()
    }
    
}


extension DomainRenewal{
    
    /**
     获取域名列表
     item: 请求需要的参数模型
     */
    private func getDomainList(userItem:RequestDomainsItem){
        let url = self.listURL
        let headers = [
            "X-API-Key":userItem.key,
            "X-API-Secret":userItem.secret
        ]
        print("User:\(userItem.user)")
        
        NetworkQueue.get(url: url, headers: headers) {[unowned self] resultData, statusCode, request, response in
            //print("Domain List StatusCode:\(statusCode)")
            if let resultData, let resultString = String(data: resultData, encoding: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let list = try jsonDecoder.decode(ResponseDomainList.self, from: resultData)
                                        
                    // 获取配置中指定需要延期的域名
                    var configureDomainList:[String] = []
                    if let _domains = userItem.domains{
                        configureDomainList += _domains
                    }
                    let isMatch = configureDomainList.count > 0 ? true : false
                    
                    var ignoreDomains:[ResponseDomainItem] = []
                    var renewalDomains:[ResponseDomainItem] = []
                    for item in list.subdomains {
                        if isMatch {
                            if configureDomainList.contains(item.full_domain){
                                renewalDomains.append(item)
                            }else{
                                ignoreDomains.append(item)
                            }
                        }else{
                            renewalDomains.append(item)
                        }
                    }
                    
                    //忽略的域名
                    if ignoreDomains.count > 0 {
                        var pushMsg = "忽略的域名:\n"
                        for item in ignoreDomains{
                            let msg = "⚠️忽略⚠️：\(item.full_domain)"
                            print(msg)
                            pushMsg += item.full_domain + "\n"
                        }
                        //pushMsg += "\n"
                        self.msgDict[userItem.user] = pushMsg
                        print("")
                    }
                    
                    if renewalDomains.count > 0 {
                        var pushMsg = self.msgDict[userItem.user] ?? ""
                        pushMsg += "延期的域名:\n"
                        self.msgDict[userItem.user] = pushMsg
                    }
                    
                    
                    // 执行需要延期的域名
                    for item in renewalDomains {
                        self.postDomainRenewal(userItem:userItem, item: item, headers: headers)
                    }
                    print("")
                    
                } catch  {
                    let msg = "域名列表获取失败  -> JSONDecoder Error"
                    print(msg)
                    print("域名列表获取响应数据:\n\(resultString)\n\n")
                    self.msgDict[userItem.user] = msg
                }
            }else{
                let msg = "域名列表获取失败 -> Body为空"
                print(msg)
                self.msgDict[userItem.user] = msg
            }
        } fail: { error, request in
            let msg = "域名列表获取失败 -> 网络请求失败"
            print(msg)
            self.msgDict[userItem.user] = msg
        }

    }
    
    /**
     延期指定域名
     */
    private func postDomainRenewal(userItem:RequestDomainsItem, item:ResponseDomainItem, headers:[String:Any]){
        let msg = "准备对域名：\(item.full_domain)执行延期操作..."
        print(msg)
        
        let url = self.renewalURL
        let par = [
            "subdomain_id":item.id
        ]
        
        
        NetworkQueue.post(url: url, par: par, headers: headers) { resultData, statusCode, request, response in
            //print("Domain Renewal StatusCode:\(statusCode)")
            if let resultData, let resultString = String(data: resultData, encoding: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let res = try jsonDecoder.decode(ResponseDomainRenewal.self, from: resultData)
                                        
                    var pushMsg = self.msgDict[userItem.user] ?? ""
                    if res.success {
                        let msg = "✅\(item.full_domain) -> 延期成功"
                        print(msg)
                        pushMsg += msg + "\n"
                    }else{
                        let msg = "❌\(item.full_domain) -> \(res.message)"
                        print(msg)
                        pushMsg += msg + "\n"
                    }
                    self.msgDict[userItem.user] = pushMsg
                    
                } catch  {
                    let msg = "域名延期失败  -> JSONDecoder Error"
                    print(msg)
                    print("域名延期响应数据:\n\(resultString)\n\n")
                    
                    var pushMsg = self.msgDict[userItem.user] ?? ""
                    pushMsg += msg + "\n"
                    self.msgDict[userItem.user] = msg
                }
            }else{
                let msg = "域名延期失败 -> Body为空"
                print(msg)
                
                var pushMsg = self.msgDict[userItem.user] ?? ""
                pushMsg += msg + "\n"
                self.msgDict[userItem.user] = msg
            }
        } fail: { error, request in
            let msg = "域名延期失败 -> 网络请求失败"
            print(msg)
            print("域名延期失败Error:\n\(error)\n\n")
            
            var pushMsg = self.msgDict[userItem.user] ?? ""
            pushMsg += msg + "\n"
            self.msgDict[userItem.user] = msg
        }
    }
    
    private var platform:String{
    #if os(macOS)
        let platform = "macOS"
    #elseif os(Linux)
        let platform = "Linux"
    #else
        let platform = "Other"
    #endif
        return platform
    }
    
    /**
     推送通知
     */
    private func push(){
        var msg = ""
        let keys = self.msgDict.keys.sorted()
        for k in keys {
            let v = self.msgDict[k] ?? ""
            msg += "用户: \(k)\n\(v)"
            msg += "\n"
        }
        

        if msg.isEmpty{
            print("✅✅没有消息可通知✅✅")
            return;
        }
        
        
        // 这是使用了零宽字符\u{200B}占位，来处理Server酱中一个\n无法换行问题。
        let body = msg + "\u{200B}\n运行环境：\(platform)\n检查时间：\(currentDate())"
                
        let title = "✅dnshe.com✅ - 免费域名定时延期"
        let subTitle = ""
        let group = "DNSHE"
        
        
        print("推送通知:")
        print("\(title)\n\(subTitle)\(body)")
        print("")
        
        
        PushBark_Github.pushAll(title: title, subTitle: subTitle, body: body, group: group)
        
    }
    
    
    /**
     获取当前时间 - 使用中国时区
     */
    private func currentDate() -> String{
        let dateFormatter = DateFormatter()
        //固定为中国时区
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = dateFormatter.string(from: Date())
        return dateStr
    }
    
}











/**
 请求时每个用户需要的参数的数据模型。
 */
private struct RequestDomainsItem:Codable{
    /** 用户描述 */
    var user:String
    
    /** 认证X-API-Key */
    var key:String
    /** 认证X-API-Secret */
    var secret:String
    
    /** 需要延期的域名，如果该值为空或者不存在，则会延期当前用户中的所有域名 */
    var domains:[String]?
    
    enum CodingKeys: String,CodingKey{
        case user = "User"
        
        case key = "X-API-Key"
        case secret = "X-API-Secret"
        
        case domains = "Domains"
    }
}



/**
 获取所有域名时响应结果数据模型
 */
private struct ResponseDomainList:Codable{
    var success:Bool
    var count:Int
    var subdomains:[ResponseDomainItem]
}


/**
 获取所有域名时响应结果 - 中subdomains对应的Item数据模型
 */
private struct ResponseDomainItem:Codable{
    var id:Int
    // 域名全称
    var full_domain:String
    
    // 创建时间
    var created_at:String
    // 过期时间
    var expires_at:String
    
    // 是否永不过期 - 0：不是
    var never_expires:Int
    
    
    // 2026-08-10 22:30:49
    var dateFormatter:DateFormatter{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }
    
    /** 是否可以执行延期操作 - 到期时间小于180天才允许 */
    var isRenewal:Bool{
        var createAt = Date()
        var expiresAt = Date()
        if let date = dateFormatter.date(from: created_at) {
            createAt = date
        }else{
            print("ResponseDomainItem：created_at日期类型转换失败")
        }
        
        if let date = dateFormatter.date(from: expires_at) {
            expiresAt = date
        }else{
            print("ResponseDomainItem：expires_at日期类型转换失败")
        }
        
        //天数计算
        let day = Int(abs(createAt.timeIntervalSince(expiresAt)) / 86_400)
        print("域名：\(full_domain) 还有\(day) 天才能延期")
        
        // 小于180天才允许延期
        if day < 180 {
            return true
        }
        
        // 默认每次运行都会尝试延期操作
        return true
    }
}


/**
 域名延期响应结果数据模型
 */
private struct ResponseDomainRenewal:Codable{
    // 是否成功
    var success:Bool
    // 消息提示
    var message:String
}
