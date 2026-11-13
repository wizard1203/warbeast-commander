# 公开源码预览版状态

更新日期：2026-11-13。公开仓库：[wizard1203/warbeast-commander](https://github.com/wizard1203/warbeast-commander)。三族源码已推送至`main`；这是需自备合法素材的源码预览版，尚未提供独立安装包或可试玩的GitHub Release。

已完成的范围：显式允许清单的代码／纯JSON副本；三族入口；MIT及作者／第三方说明；无像素、原片、声音、模型、导入缓存、原生二进制或历史运行证明。仅新候选启动器去除私人音效强依赖，原规则源码不改。

本轮重新完成Godot 4.7.2 Standard的干净编辑器导入，503项首发目录、准入及实际界面选择器检查全部通过。随后用合法本地Starter ZIP完成“未安装明确报错→安装七张PNG→校验通过”，重新导入素材，并分别通过正常对局入口及竞技场入口的原生短启动（各`--quit-after 120`，退出码0；日志未见ERROR、SCRIPT ERROR、Parse Error或WARNING）。这仅覆盖启动，不是整局战斗、人工画面、音效、物理操作或性能验收；原录像资格不自动适用于本包。

初始允许清单581项源码／元数据，全部字节在上述测试中保持不变；Godot另生成90项合法且具有对应GDScript的`.gd.uid`资源身份文件，纳入671项源码清单。测试后的首个准备快照只更新本状态文件；此次发布再单独更新本文件及第三方声明中的公开状态，不改运行时代码。初始公开源码提交为[7f8e756](https://github.com/wizard1203/warbeast-commander/commit/7f8e756b01bf95dae63d699a40c2be36ffa2deb1)。安装到本机的Starter PNG、安装凭据、`.import`及`.godot`均未进入Git提交；录像、私人音包、模型及本机原生二进制也未上传。

目前不提供已签名／公证的独立Mac App，不宣称Windows、Linux、iOS、Android或24FPS已获认证。原生加速与预烘焙资产缺失时会回退，须测量真实性能。私人新音效不在本包，运行默认静音。素材边界见[安装说明](ASSET_INSTALLATION.md)和[第三方声明](../THIRD_PARTY_NOTICES.md)。
