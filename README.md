## AutoTaskPublic
- 该仓库主要是用来运行一些AutoTask仓库不适合的Action任务。
- 由于该仓库是公开仓库，所以GitHub Action没有时间限制。
- 运行的Action的任务，一般是在macOS环境中。
- 如果需要设置一些私密数据，请通过Github环境变量设置。


## code-kit
用于存放一些通用公共的代码，这些代码会给其他任务提供服务；\
比如：\
**DomainConnectivityCheck**就使用了`code-kit/swift`下面的：\
`EnvManager.swift`，`Network.swift` 和`PushBark_Github.swift`文件。


## 环境变量
如果action任务需要配置环境变量，直接去查看AutoTask中code-dev目录中的对应配置说明即可。



## 执行的任务:


### 1. domains/DomainConnectivityCheck
检测指定域名是否能够正常访问，如果不能正常访问；\
则使用`domains/pushbark/PushBark_Github.swift` 发送通知；\
支持接收通知的App:：Bark，Server酱，PushDeer 