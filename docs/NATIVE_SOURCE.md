# 可选原生源码

本源码包保留碰撞／导航C++实现、构建脚本及MIT许可，但不附二进制、GDExtension描述符或开发机资格报告。游戏后端缺包时保留完整GDScript路径，不下载依赖。不能把这个源码副本说成已启用跨平台加速。

`native/body_resolver_m94/VENDOR_LOCK.json`固定godot-cpp提交及接口SHA。body的CMake默认只构建纯核心smoke测试；扩展构建需显式提供匹配godot-cpp源、生成头及可选静态库。navigation构建也需要显式的固定外部源、生成头和静态库；本仓库不vendor依赖或自动构建SDK。

新的原生安装包须建立完整来源／二进制manifest，真实对照GDScript规则和完整会话，核验平台、引擎／可执行文件身份及导出App表现。不能复用开发编辑器的历史资格，不能只添加一个dylib跳过其余校验。来源：<https://github.com/godotengine/godot-cpp>；各目录保留自己的LICENSE及godot-cpp MIT副本。
