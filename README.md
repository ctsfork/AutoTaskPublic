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




## PushBark
在任意Swift脚本中如果需要推送通知，则需要将PushBark.swift引入，它提供了多个平台的消息推送接口服务。 \
\
封装了几个平台的消息通知发送服务，其中包括：
- Bark：https://github.com/Finb/Bark
- Server酱：https://sc3.ft07.com/client
- PushDeer：https://www.pushdeer.com/product.html


**Giuhub**版本环境变量配置:
```
//Server酱³请求API URL - 其中包括完整的SendKey
//这个URL是由https://sc3.ft07.com/平台生成的。
PushBark_sc3API=


//PushDeer消息发送API URL，其中的pushkey在PushDeer App中获取。
PushBark_pushDeerAPI=


//Bark消息发送API URL - key（在Bark App中获取）放在Body参数中。并且可以推送多个设备。
PushBark_barkAPIs=
//推送设备的key数组
PushBark_barkKeys=
```
⚠️注意⚠️：\
如果环境变量需要形如字典，数组等数据时，需要以JSON字符串的方式配置环境变量；\
像普通的：字符串，数字，Bool类型直接配置环境变量皆可，配置Bool值时支持false/true和数字(0解析为false，非0解析为true)。






##
## 执行的任务:


### 1. domains/DomainConnectivityCheck
检测指定域名是否能够正常访问，如果不能正常访问；\
则使用`domains/pushbark/PushBark_Github.swift` 发送通知；\
支持接收通知的App:：Bark，Server酱，PushDeer 