//
//  PushBark_Github.swift
//  
//
//  Created by kimi on 2026/9/22.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif





/**
 推送消息发送管理（Github版本），支持平台：
 - Bark：只支持iOS平台，并且持续更新。 -  如果支持用iPhone设备则推荐使用这个。
 - Server酱³：支持iOS/Android平台，并且持续更新。
 - Server酱Turbo：只要集成其它平台，比如默认就是微信公众号接收通知。
 - PushDeer：支持iOS/Android平台，但是代码已经不更新了。
 
 
 ⚠️关于Github版本：
 GitHub版和普通版的区别就是：
 1. GitHub版将普通版中的敏感数据放在了环境变量中，运行时先从环境变量中获取并配置数据。
 2. 获取环境变量时会使用EnvManager.swift
 
 
 下载地址：
 1. Bark：
     - https://github.com/Finb/Bark
     - https://apps.apple.com/us/app/bark-custom-notifications/id1403753865
 2. Server酱：https://sc3.ft07.com/client
 3. PushDeer：https://www.pushdeer.com/product.html
 
 
 通知接送强度优先级：
 Bark > PushDeer > Server酱
 
 
 推荐：
 在发送推送服务时，推荐同时推送到这三个平台。
 
 
 PS: 该工具可用于Swift脚本运行
 */
class PushBark_Github
{
    
//MARK: - Server酱
    
    /**
     Server酱³请求API URL
     https://[uid].push.ft07.com/send/[SendKey].send
     这个URL是由https://sc3.ft07.com/平台生成的。
     其中：27862和sctp2lqmq是对应的uid和sendKey
     */
    private static var sc3API = ""
    
    /**
     Server酱Turbo请求API URL
     https://sctapi.ftqq.com/<SendKey>.send
     SENDKEY: 由https://sct.ftqq.com/平台生成
     */
    private static var scTurboAPI = ""
    
    
    
    
    /**
     功能：Server酱推送服务，接收消息时需要再手机上安装[Server酱 App] - 同时支持iOS/Android，并且App在持续更新。
     Server酱消息发送服务是收费的，免费服务每天只能发送5条消息。
     -
     该API消息发送支持：
         Server酱3: 向Server酱App推送消息服务 - iOS和Android都在持续更新，并且支持无后台通知。 - 推荐使用
         Server酱Turbo: 根据站点通道配置可推送到不同的平台，默认推送到微信公众号
     -
     - url: 发送通知的API URL，支持Server酱³/Server酱Turbo
     -
     - title/text: 推送的标题，如果未提供则使用 text 的内容 - 必填
     - desp:  推送的正文内容，如未提供 title，则为必填，支持markdown（在APP中显示）
     - short: 推送消息的简短描述，用于指定消息卡片的内容部分，尤其是在推送markdown的时候
     - tags: 标签列表，多个标签使用竖线分隔
     -
     PS:
        1. Server酱³：https://sc3.ft07.com/
        2. Server酱Turbo：https://sct.ftqq.com
        3. 文档地址：https://doc.sc3.ft07.com/zh/serverchan3/server/api
     */
    @discardableResult
    static func serverChan_send(url:String = sc3API, title: String, short:String? = nil, desp: String? = nil, tags:String? = nil) -> String {
        print("Server酱消息发送：")
        
        guard let url = URL(string: url) else {
            print("Server酱 Invalid URL")
            return ""
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //body参数
        var dict:[String:String] = [
            "title":title,
        ]
        dict["desp"] = desp
        dict["short"] = short
        dict["tags"] = tags
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict){
            request.httpBody = jsonData
        }
        
        
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        
        
#if canImport(FoundationNetworking)
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: cfg)
#else
        let session = URLSession.shared
#endif
        
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Server酱 Error: \(error)")
            } else if let data = data {
                result = String(data: data, encoding: .utf8) ?? ""
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        
        return result
    }
    
    
    
    
//MARK: - PushDeer
    /**
     PushDeer消息发送API URL，其中的pushkey在PushDeer App中获取。
     */
    private static var pushDeerAPI = ""
    
    /**
     功能：PushDeer推送服务，接收消息时需要再手机上安装[PushDeer App] - 同时支持iOS/Android；但是Android已经停止更新，iOS版也比较老旧了。
     PushDeer消息发送服务是免费的，正常使用消息数量是不限制的。
     -
     - pushkey：PushKey从PushDeerApp中获取，目前该参数已经放在了URL Query中
     -
     - url：发送通知的API URL
     -
     - text：推送消息内容
     - desp：消息内容第二部分，选填
     - type：格式，选填文本=text，markdown，图片=image，默认为markdown。当type为image时，text中为要发送图片的URL。
     
     PS:
        站点：https://www.pushdeer.com/dev.html
     */
    @discardableResult
    static func pushdeer_send(url:String = pushDeerAPI, text: String, desp: String? = nil, type:String? = "text") -> String {
        print("PushDeer消息发送：")
        
        guard let url = URL(string: url) else {
            print("PushDeer Invalid URL")
            return ""
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //body参数
        var dict:[String:String] = [
            "text":text,
        ]
        dict["desp"] = desp
        /**
         消息类型-可选，支持：
         - text - text中为要发送图片的URL
         - image
         - markdown - 默认
         */
        dict["type"] = type
        
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict){
            request.httpBody = jsonData
        }
        
        
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        
        
#if canImport(FoundationNetworking)
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: cfg)
#else
        let session = URLSession.shared
#endif
        
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("PushDeer Error: \(error)")
            } else if let data = data {
                result = String(data: data, encoding: .utf8) ?? ""
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        
        return result
    }
    
    
    
    
//MARK: - Bark

    /**
     Bark消息发送API URL - key（在Bark App中获取）直接放在URL中，并且只能推送一个设备。
     */
    private static var barkAPI = ""
    
    /**
     Bark消息发送API URL - key（在Bark App中获取）放在Body参数中。并且可以推送多个设备。
     需要参数：
     - device_key：只推送一个设备
     - device_keys：推送多个设备，公共服务器一次最多 10 个设备，自建服务器无上限。
     */
    private static var barkAPIs = ""
    /** 推送设备的key数组 */
    private static var barkKeys = [
        ""
    ]
    
    /**
     功能：Bark推送服务，接收消息时需要再手机上安装[Bark App] - 只支持iOS，并且App在持续更新。
     Bark消息发送服务是免费的，正常使用消息数量是不限制的。
     
     
     主要参数：
     title: 推送标题，显示在通知卡片的第一行。不传时通知只显示正文；
     subtitle: 推送副标题，显示在标题下方、正文上方的较小字号位置，适合放来源、状态之类的补充信息。不传则不显示这一行；
     body: 推送正文，通知卡片上的主要内容。换行请使用换行符 '\n'
     markdown：推送正文，支持基础 Markdown 格式，传了这个参数会忽略 body。
     
     
     设备：
     device_key：推送目标设备的 key，作用和 URL 路径里的 key 一样。
                 JSON 请求且路径为 /push 时，用它把 key 放进请求体，用法参考使用教程。
                 这个参数由服务器使用，App 本身不读取。
     device_keys：key数组，一次推送给多台设备，仅支持 JSON 请求，
                  公共服务器一次最多 10 个设备，自建服务器无上限；需要 bark-server v2.1.9 及以上版本。
     
     展示与分组：
     group：对消息分组，同一个 group 的推送在系统通知中心和历史记录里会归到一组
     icon： 自定义通知图标，填图片 URL，设置后会替换通知里默认的 Bark 图标。
     image：推送图片的 URL，收到推送后展开通知即可看到大图，App 历史记录里也会显示。图片同样会缓存在本机，下载超过 10 秒时这条推送不带图片显示。
     badge：App 图标上的角标数字，直接设置成传入的值，不会在原有数字上累加。传 0 会清除角标，同时清掉通知中心里该 App 的通知。
     
     提醒与铃声：
     level：推送的级别，可选值：
        - active：默认值，系统会立即亮屏显示通知
        - timeSensitive：时效性通知，专注模式下也能显示
        - passive：仅将通知添加到通知列表，不会亮屏提醒
        - critical：重要警告，静音模式下也会响铃。
     volume：重要警告（level=critical）的通知音量，取值范围 0-10，不传默认值为 5。
     call：传"1"时把通知铃声循环播放 30 秒（默认只响一次），用于需要强提醒的场景。配合 sound 指定铃声；和 level=critical 一起用时可以用 volume 调整音量。
     sound：推送使用的铃声名称，例如 minuet。App
            内置铃声和自己导入的铃声都可以用，导入的铃声需要是 .caf 格式、时长不超过 30 秒，导入方法见 App 内的铃声设置。
            不传时使用 App 设置里的默认铃声；名称不存在时系统会回退到默认提示音。
     
     复制与跳转：
     copy：指定复制推送时复制的内容，比如只复制正文里的验证码。不传这个参数时，复制到的是推送正文；
     url：点击推送时跳转的 URL，支持 URL Scheme 和 Universal Link。
          http/https链接会优先用Universal Link打开，失败时用Safari打开，其他Scheme直接交给系统处理。
     action：传 alert 时，点击推送打开 App 会弹出操作弹窗，可以复制推送内容或分享出去。
            传 none 时点击推送只打开 App，不跳转到具体页面；其他值按默认行为处理。
            同时传了 url 时优先按 url 跳转。
     
     加密：
     ciphertext：加密推送的密文，推送内容对 Bark 服务器和苹果 APNs 都不可见，只有本机 App 能解密。
                 密文里可以放 title、subtitle、body、sound、group、badge 等参数，具体加密方法见推送加密。
                 解密失败时通知内容会显示 Decryption Failed。
     iv：供加密推送使用。加密时使用的随机 IV 值，需要将其一并传给服务器；
     
     
     保存与管理：
     isArchive：是否把这条推送保存到 App 的历史记录。传 1 保存，传其他值不保存。不传时按 App 内的设置决定是否保存，默认为保存。
     ttl：已保存推送的有效期，单位为秒，只对保存到历史记录的消息生效。
          到期后 App 会自动删除这条历史记录，同时移除通知中心里对应的推送；
          适合只在一段时间内有意义的消息，比如验证码、临时告警。
     id：通知的唯一标识。使用相同的 id 时，新的推送会更新替换原来那条通知，不会重复堆在通知中心里，适合做进度、状态类通知。
         需要 Bark v1.5.2、bark-server v2.2.5 及以上版本；JSON 传参必须使用字符串类型，传数字不生效。
         删除通知（delete）也需要靠它来定位。
     delete：传 "1" 时删除指定通知，会同时从系统通知中心和 App 历史记录里删掉，需要搭配 id 使用。
             这条指令通过静默推送下发，需要在系统设置里为 Bark 打开「后台App刷新」，否则无效。
     
     
     PS:
        1. https://bark.day.app/#/
        2. https://github.com/finb/bark
     */
    @discardableResult
    static func bark_send(ApiURL:String = barkAPIs, barkKeys:[String] = barkKeys , title: String, subtitle: String? = nil,body: String? = nil, group:String? = nil, level:String? = "critical" ) -> String {
        print("Bark消息发送：")
        
        guard let url = URL(string: ApiURL) else {
            print("Bark Invalid URL")
            return ""
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //body参数
        var dict:[String:Any] = [
            "device_keys":barkKeys,
            "title":title,
        ]
        dict["subtitle"] = subtitle
        dict["body"] = body
        dict["group"] = group
        dict["level"] = level
        dict["badge"] = 1
        
        
        
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict){
            request.httpBody = jsonData
        }
        
        
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        
        
#if canImport(FoundationNetworking)
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: cfg)
#else
        let session = URLSession.shared
#endif
        
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Bark Error: \(error)")
            } else if let data = data {
                result = String(data: data, encoding: .utf8) ?? ""
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        
        return result
    }
    
}




//MARK: - EnvManager
extension PushBark_Github{
    /**
     读取环境变量中的配置信息 - 使用Github版时必须先执行这个方法
     */
    static func setupEnvironment(){
        print("从环境变量中读取配置......")
        
        //Server酱
        let PushBark_sc3API = EnvManager.shared.getString(name: "PushBark_sc3API")
        
        // PushDeer
        let PushBark_pushDeerAPI = EnvManager.shared.getString(name: "PushBark_pushDeerAPI")
        
        // Bark
        let PushBark_barkAPIs = EnvManager.shared.getString(name: "PushBark_barkAPIs")
        let PushBark_barkKeys = EnvManager.shared.getArrayString(name: "PushBark_barkKeys")
        
        
        
        if let PushBark_sc3API {
            self.sc3API = PushBark_sc3API
        }else{
            print("❌PushBark Environment - PushBark_sc3API❌：Server酱³ 请求API获取失败")
        }
        
        if let PushBark_pushDeerAPI {
            self.pushDeerAPI = PushBark_pushDeerAPI
        }else{
            print("❌PushBark Environment - PushBark_pushDeerAPI❌：PushDeer 请求API获取失败")
        }
        
        
        if let PushBark_barkAPIs {
            self.barkAPIs = PushBark_barkAPIs
        }else{
            print("❌PushBark Environment - PushBark_barkAPIs❌：Bark 请求API获取失败")
        }
        if let PushBark_barkKeys {
            self.barkKeys = PushBark_barkKeys
        }else{
            print("❌PushBark Environment - PushBark_barkKeys❌：Bark 推送设备keys数组获取失败")
        }
        
    }
    
    
    /**
     打印配置环境变量后的数据
     */
    private  static func printEnvironment(){
        print("self.sc3API:\(self.sc3API)")
        print("self.pushDeerAPI:\(self.pushDeerAPI)")
        print("self.barkAPIs:\(self.barkAPIs)")
        print("self.barkKeys:\(self.barkKeys)")

    }
    
}




//MARK: -
extension PushBark_Github{
    
    /**
     同时推送PushBark支持的所有通知
     - title: 标题
     - subtitle: 子标题
     - body: 长内容
     - group: 分组
     - type: 通知分组
     */
    static func pushAll(title:String, subTitle:String?, body:String, group:String?, type:String? = nil){
        //GitHub版必须配置setupEnvironment
        setupEnvironment()
        
        
        // Server酱的换行有些问题，这是使用了零宽字符\u{200B}占位，来处理一个\n无法换行问题。
        let bodyServerChan = body.replacingOccurrences(of: "\n", with: "\n\n")
        
        
        //推送
        bark_send(title: title, subtitle: subTitle, body: body, group: group)
        serverChan_send(title: title, short:subTitle, desp: bodyServerChan, tags:group)
        pushdeer_send(text: title , desp: body)
    }
    
    
}








//MARK: - Test
extension PushBark_Github{
    
    static func testServer酱3(){
        let ret = serverChan_send(title: "主人服务器宕机了 via swift", short:"推送消息的简短描述不会在点开通知中显示", desp: "内容第一行\r\n\n内容第二行",  tags:"CTSServer")
        print(ret)
    }
    
    static func testPushDeer(){
        let ret = pushdeer_send(text: "主人服务器宕机了 via swift", desp: "内容第一行\r\n\n内容第二行")
        print(ret)
    }
    
    
    static func testBark(){
        let ret = bark_send(title: "主人服务器宕机了 via swift", subtitle: "副标题", body: "内容第一行\r\n\n内容第二行", group: "CTSServer")
        print(ret)
    }
    
}





//PushBark_Github.testServer酱3()
//PushBark_Github.testPushDeer()
//PushBark_Github.testBark()







//MARK: - 关于运行
/**
 可以使用：swift file1.swift file2.swift的
 
 运行方式：
 
 1. 将Swift文件作为脚本的方式运行，直接使用swift命令即可。
 例如：
    swift file1.swift file2.swift
 如果有多个文件，可以使用:
    swift *.swift 的方式运行。
 
 注意：
    1. 即使swift命令后面可以支持多个文件，但是第一个文件之后的swift文件，是作为参数的。
    2. 如果使用swift命令运行多个swift文件，和想象中那种编译方式的运行逻辑，一次只能运行一个swift脚本。
 
 
 2. 如果需要单独运行多个swift文件(不是作为一个项目)，可以使用swiftc命令编译出可执行程序，然后再运行可执行程序。
 命令：
    swiftc PushBark.swift main.swift -o PushBark
 或者：
    swiftc PushBark.swift RunPushBark.swift -o PushBark
 
 注意：
    1. swiftc命令编译时，需要一个程序入口，程序入口有两种方式：
        - 使用main.swift文件作为程序入口，其中可以运行顶级函数。
        - 使用自定义的任何swift文件，在文件中创建一个class/struct然后使用: @main 包装器命令描述指定class/struct
          然后在这个class/struct中实现public static func main() 方法作为程序入口
    2. swiftc命令后的swift文件是无序的，但是需要提供一个程序入口
 
 */

