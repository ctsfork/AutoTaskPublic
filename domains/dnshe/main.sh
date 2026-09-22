#!/usr/bin/env bash 



## 根据执行命令(终端第一个参数)获取脚本所在目录，与相关目录
## 用来解决脚本在任何位置都能正常运行
SOURCE="$0"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"  
    SOURCE="$(readlink "$SOURCE")" # 获取软连接对应真实的文件路径

    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
## 当前脚本的真实所在的目录
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
## 当前脚本的真实全路径
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$SOURCE")"
## 脚本所在的主目录
HomePath="$(dirname "$SCRIPT_DIR")"


# echo "SCRIPT_DIR:${SCRIPT_DIR}"
# echo "SCRIPT_PATH:${SCRIPT_PATH}"
# echo "HomePath:${HomePath}"






## 进入脚本所在的目录
cd "${SCRIPT_DIR}"
# pwd



## 编译
# echo "编译......"
swiftc DnsheDomainRenewal.swift ../../code-kit/swift/pushbark/PushBark_Github.swift ../../code-kit/swift/core/*.swift -o DnsheDomainRenewal



## 执行
# echo "执行......"
./DnsheDomainRenewal



## 清除
rm DnsheDomainRenewal





