//
//  NetworkQueue.swift
//  
//
//  Created by kimi on 2026/9/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif





/**
 Network的操作队列版，支持串行和并发请求。
 串行：- 可以同时添加很多任务，但同时只会执行一个任务。
 并发：
 
 isConcurrency控制串行还是并发。
 
 waitUntilAllOperationsAreFinished()方法用于等待OperationQueue中已经存在的Operation完成。
 
 ⚠️警告⚠️：
 1. NetworkQueue和Network这两个版本都是对URLSession的简单封装，在Linux平台有同样的问题，使用时需要注意。
 2. NetworkQueue可以在一个请求中添加另一个请求，但是需要注意不能再请求内部进行 waitUntilAllOperationsAreFinished()操作，它会阻塞线程。
    因该在请求外面进行wait等待操作，或者使用不同的OperationQueue对象(当前所有请求使用的是同一个)。
 3. Network实现了串行，但是不能在一个请求中添加另一个请求会造成阻塞。所有请求应该保持在同一级(不能一个在另一个的内部)。或者直接使用NetworkQueue。
 */
class NetworkQueue
{
    /**
     是否并发请求，默认true。
     true：并发执行所有请求，最大支持32线程。
     false：串行依次支持请求，此时只有一个线程。
     */
    public static var isConcurrency:Bool{
        set{
            if newValue {
                operationQueue.maxConcurrentOperationCount = 32
            }else{
                operationQueue.maxConcurrentOperationCount = 1
            }
        }
        get{
            if operationQueue.maxConcurrentOperationCount == 1 {
                return false
            }else{
                return true
            }
        }
    }
    
    /**
     等待所有已经添加到OperationQueue中的Operation完成
     警告：不要在Operation操作中进行等待，这会造成阻塞。
     */
    public static func waitUntilAllOperationsAreFinished(){
        operationQueue.waitUntilAllOperationsAreFinished()
    }
    
    
    
    /** 功能：是否允许对整个URL CharacterSet.urlQueryAllowed编码 - 默认允许 */
    public static var allowedURLEncoding:Bool = true
    

    
    /**
     Content-Type类型自定义
     */
    public static var contentType = "application/json"
    public static var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 13) AppleWebKit/618.11 (KHTML, like Gecko) Version/17.1.63 Safari/618.11"
    
}


extension NetworkQueue{
    /** 配置默认的OperationQueue */
    private static var operationQueue:OperationQueue = createOperationQueue()
    private static func createOperationQueue() -> OperationQueue{
        let queue = OperationQueue()
        queue.name = "com.urlsession.concurrent"
        queue.maxConcurrentOperationCount = 32
        return queue
    }
    
    /** Linux下每次请求就创建一个URLSession对象，macOS下使用共享的URLSession.shared */
    private static var session:URLSession{
#if canImport(FoundationNetworking)
        return createSession()
#else
        return URLSession.shared
#endif
    }
    private static func createSession() -> URLSession{
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: cfg)
        return session
    }
}


extension NetworkQueue{
    
    /**
     Linux平台URLSession的使用警告
     */
    public static func linuxWarning(){
#if os(Linux)
    print("⚠️⚠️警告⚠️⚠️：当前是在Linux平台上运行，URLSession要慎用，如果强制使用URLSession则需要请求的域名能被URLSession正确支持。")
#endif
    }
    
 
    
    /**
     基础请求
     - url：请求URL
     - method: 请求方式，形如GET/POST
     - par: 请求参数
     - headers: headers
     - success：请求成功回调
     - fail：请求失败回调
     */
    public class func base(url:String,
                           method:String?,
                           par:[String:Any]?,
                           headers:[String:Any]? = nil,
                           success:@escaping (_ resultData:Data?, _ statusCode:Int, _ request:URLRequest, _ response:URLResponse?) -> Void,
                           fail:@escaping (_ error:Error, _ request:URLRequest) -> Void )
    {
        linuxWarning()
        
        guard let url = URL(string: url) else{
            print("Invalid URL:\(url)")
            return;
        }
        
        var request = URLRequest(url: url)
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        /** 配置headers */
        if let headers {
            for (name, value) in headers{
                request.setValue((value as! String), forHTTPHeaderField: name)
            }
        }
        
        
        if let _method = method  {
            let method = _method.uppercased()
            request.httpMethod = method
            
            // 添加Body参数
            if ["POST", "PUT", "PATCH"].contains(method){
                if let dict = par {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: dict){
                        request.httpBody = jsonData
                    }
                }
            }
            
        }
        
        
        // 创建URLSession请求Operation
        let operation = URLSessionTaskOperation(session: self.session, request: request) { resultData, statusCode, request, response in
            success(resultData, statusCode, request, response)
        } fail: { error, request in
            fail(error, request)
        }

        //添加到队列中
        self.operationQueue.addOperation(operation)
        
        
    }
    
    
    
}


extension NetworkQueue{
    
    /**
     URLSession实现的网络请求功能
     请求方式：GET
     - url：请求URL
     - headers: headers
     - success：请求成功回调
     - fail：请求失败回调
     */
    public class func get(url:String,
                          headers:[String:Any]? = nil,
                          success:@escaping (_ resultData:Data?, _ statusCode:Int, _ request:URLRequest, _ response:URLResponse?) -> Void,
                          fail:@escaping (_ error:Error, _ request:URLRequest) -> Void )
    {
        base(url: url, method: "GET", par: nil, headers: headers, success: success, fail: fail)
    }
    
    
    /**
     URLSession实现的网络请求功能
     请求方式：POST
     - url：请求URL
     - par：请求参数
     - headers: headers
     - success：请求成功回调
     - fail：请求失败回调
     */
    public class func post(url:String,
                           par:[String:Any]?,
                           headers:[String:Any]? = nil,
                           success:@escaping (_ resultData:Data?, _ statusCode:Int, _ request:URLRequest, _ response:URLResponse?) -> Void,
                           fail:@escaping (_ error:Error, _ request:URLRequest) -> Void )
    {
        base(url: url, method: "POST", par: par, headers: headers, success: success, fail: fail)
    }
    
}















//MARK: - 重写SupportSerialOperation，让其控制URLSession  让其能够自由控制串行/并发操作
private class URLSessionTaskOperation:SupportSerialOperationV1, @unchecked Sendable {
    //用于在普通方法中调用async的Task
    private var task:URLSessionDataTask?

    private var session:URLSession
    private var request:URLRequest
        
    
    /**
    请求成功block
     resultData：响应数据
     statusCode：响应状态码
     request：请求对象
     response：响应对象
    */
    private var blockSuccess:((_ resultData:Data?,_ statusCode:Int,_ request:URLRequest, _ response:URLResponse?) -> Void)?
    
    /**
     请求失败的block
     error：请求错误信息
     */
    private var blockFail:((_ error:Error, _ request:URLRequest) -> Void)?
   

    

    /// 初始化操作
    /// - Parameters:
    ///   - session: 请求客户端
    ///   - request: 请求参数
    ///   - progress: 请求进度回调
    ///   - success: 请求成功回调，其中是否返回响应数据与outputPath的值是否存在相关，如果存在并且是一个正确的路径那么将不会返回响应数据，反之一定会返回响应数据(如果响应数据为空则会返回一个空的Data数据)
    ///   - fail: 请求错误
    init(session: URLSession,
         request: URLRequest,
         isShutdown:Bool = false,
         success:@escaping (_ resultData:Data?,_ statusCode:Int,_ request:URLRequest, _ response:URLResponse?) -> Void,
         fail:@escaping (_ error:Error, _ request:URLRequest) -> Void)
    {
        self.session = session
        self.request = request
        
        self.blockSuccess = success
        self.blockFail = fail
    }
    
   
    
    
//MARK: - Operation OverWrite
    override func main() {
        if isCancelled {
            return
        }
        
        // 启动下载任务
        startTask()
    }
    
    override func cancel() {
        super.cancel()
        clear()
    }
    
    override func finish() {
        super.finish()
        clear()
    }
    
    /**
     清理相数据
     */
     func clear(){
         task = nil
    }
    
    
    
    
    /**
     启动URLSessionq请求任务
     */
    private func startTask() {
        let task = self.session.dataTask(with: request) { [unowned self] data, response, error in
            if let error = error {
                self.blockFail?(error, self.request)
            }else{
                let code = (response as! HTTPURLResponse).statusCode
                self.blockSuccess?(data, code, self.request, response)
            }
            
            // 标记这个操作已经完成
            self.finish()
        }
        
        task.resume()
    }
    
}






//MARK: - 重写Operation让其能够手动控制Operation的状态
private  class SupportSerialOperationV1: Operation, @unchecked Sendable {
    // MARK: - State
    private enum State {
        case ready
        case executing
        case finished
    }
    
    private let stateLock = NSRecursiveLock()
    private var _state_: State = .ready
    private var state: State {
        set{
            stateLock.lock()
            defer { stateLock.unlock() }
            _state_ = newValue
        }
        get{
            stateLock.lock()
            defer { stateLock.unlock() }
            return _state_
        }
    }
    
    
    // MARK: - Operation
    open override var isAsynchronous: Bool {
        true
    }
    
    public final override var isReady: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        return state == .ready && super.isReady
    }
    
    public final override var isExecuting: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }

        return state == .executing
    }

    public final override var isFinished: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }

        return state == .finished
    }
    
    
    
    // MARK: - Start
    public final override func start() {
        // 状态转换必须在锁内完成
        stateLock.lock()
        
        if state != .ready {
            stateLock.unlock()
            return
        }
        
        if isCancelled {
            transitionLocked(to: .finished)
            stateLock.unlock()
            return
        }

        transitionLocked(to: .executing)
        stateLock.unlock()

        // 绝对不能在锁内调用 main()
        main()
    }

    // MARK: - Main
    open override func main() {
        fatalError("Subclasses must implement main().")
    }

    // MARK: - Finish
    open func finish() {
        stateLock.lock()
        defer { stateLock.unlock() }
                
        guard state != .finished else {
            return
        }

        transitionLocked(to: .finished)
    }
    
    
    // MARK: - Change State
    private func transitionLocked(to newState: State) {
        let oldState = state
        guard oldState != newState else {
            return
        }
        
        switch (oldState, newState) {
            case (.ready, .executing):
                willChangeValue(forKey: "isExecuting")
                
                state = .executing
                
                didChangeValue(forKey: "isExecuting")
            case (.ready, .finished):
                willChangeValue(forKey: "isFinished")
                
                state = .finished
                
                didChangeValue(forKey: "isFinished")
            case (.executing, .finished):
                willChangeValue(forKey: "isExecuting")
                willChangeValue(forKey: "isFinished")

                state = .finished

                didChangeValue(forKey: "isFinished")
                didChangeValue(forKey: "isExecuting")
            default:
                fatalError( "Invalid state transition: \(oldState) -> \(newState)")
        }
        
    }
    
}








class SupportSerialOperationV2:Operation, @unchecked Sendable {
    private let stateQueue = DispatchQueue(label: "AsyncOperation.rw.state", attributes: .concurrent)
    
    override var isAsynchronous: Bool{
        true
    }

    private var _isExecuting = false
    override var isExecuting: Bool {
        get{
            return stateQueue.sync { _isExecuting }
        }
        set{
            willChangeValue(forKey: "isExecuting")
            stateQueue.sync(flags: .barrier) {
                _isExecuting = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var _isFinished = false
    override var isFinished: Bool {
        get{
            return stateQueue.sync { _isFinished }
        }
        set{
            willChangeValue(forKey: "isFinished")
            stateQueue.sync(flags: .barrier) {
                _isFinished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }

    final override func start() {
        if isCancelled {
            finish()
            return
        }

        willChangeValue(forKey: "isExecuting")
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")

        main()
    }

    override func main() {
        fatalError("Subclasses must implement `main`.")
    }


    /** 标记当前Operation任务完成，重写时需要执行super */
    func finish() {
        if _isFinished {
            return
        }
        
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")

        _isExecuting = false
        _isFinished = true

        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
}






