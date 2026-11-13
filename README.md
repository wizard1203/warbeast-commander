# Warbeast Commander · 魔兽指挥官

Godot单机像素即时战略游戏。首发开放誓图、铆炉、织叶：21种正规兵、24名英雄、12项特色科技；保留单击指挥、编队、固定建筑位与自动采金。包含正常对局和可配置英雄／军队竞技场。

## 运行

这是**不附带受限美术和声音的源码包**，不是独立安装App。需要Godot 4.7.2 Standard、Node.js 20以上，以及自行从原作者合法取得的Heroic Starter素材。不得从其他游戏提取图像代替授权包。

先按[素材安装说明](docs/ASSET_INSTALLATION.md)安装Starter，再用Godot编辑器打开项目重建导入缓存。命令行示例：

```sh
node tools/install_heroic_starter.mjs "/path/to/HAS Starter Pack.zip"
node tools/install_heroic_starter.mjs --check
godot --headless --editor --path . --quit
godot --path .
godot --path . --script res://tools/release_media/arena_bootstrap.gd
```

macOS也可双击`launch-outposts.command`或`launch-neural-arena.command`；用`GODOT_BIN`指定已安装引擎。Windows／Linux请从编辑器或命令行启动，并确保安装中文字体；这些平台和手机尚未完成发行验证。

## 素材与声音边界

Heroic Asset Series由**Aleksandr Makarov (iknowkingrabbit)**创作。原始PNG、付费包及其衍生图集不在此仓库；本地安装后的素材仍遵守作者原许可，不因代码MIT改为开源。完整来源见[CREDITS.md](CREDITS.md)和[第三方声明](THIRD_PARTY_NOTICES.md)。

私人音效包缺失时，正常对局和竞技场使用明确的静音路径；本包不下载模型，也不附带录制版神经声音或旧音频采样。可选Collection安装只恢复合同列出的作者图像，不保证重建开发录像的全部原创／派生图集、矿场裁片和特效。代码绘制的回退可能更慢；本包尚未认证后期FPS。

## 开发与检查

规则在`src/simulation/`，固定步会话在`src/runtime/`，界面与绘制在`src/presentation/`。显示和媒体不裁定伤害。可选C++纯源码保留在`native/`，本包无原生二进制，默认使用GDScript回退；见[原生源码说明](docs/NATIVE_SOURCE.md)。

首发目录／配置检查示例（输出须为新文件）：

```sh
godot --headless --path . --script res://tests/run_first_release_checks.gd -- --json=/tmp/warbeast-first-release-checks-new.json
```

这不是全部历史回归、原生画面／音效、手机或平衡认证。当前公开候选状态见[RELEASE_STATUS.md](docs/RELEASE_STATUS.md)。自有代码使用[MIT](LICENSE)；第三方权利不变。本项目与Hero's Hour、Warcraft、League of Legends、Dota及其发行商无官方或授权关联。
