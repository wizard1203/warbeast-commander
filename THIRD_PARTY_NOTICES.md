# Third-party notices and license scope

核查日期：2026-11-13。用户已确认：拟建公开仓库`wizard1203/warbeast-commander`，自有代码采用MIT。当前仍是本机发布准备，尚未创建远端仓库或GitHub Release。

## 1. MIT的范围

根目录 [LICENSE](LICENSE)适用于本项目自行编写、由贡献者有权授权的程序源码及随附说明。它不重新许可第三方代码、Heroic像素素材、由这些素材加工的图像／图集、模型、字体、私人音频或录像中的第三方内容。已有独立许可必须保留；不能用根目录MIT替换它们。

本地工作目录不是公开源码包。不能直接`git add .`或上传整目录；也不能用Git LFS、Base64、缓存文件、压缩包、生成图集或历史提交规避素材限制。`assets/art/original/`的名称本身不证明独立创作或可再分发。

## 2. Heroic Asset Series

作者：**Aleksandr Makarov (iknowkingrabbit)**。完整逐包官方链接与署名在 [CREDITS.md](CREDITS.md)。本地来源凭据为`assets/art/heroic/manifest.json`、`collection-manifest.json`、`pixel-world-manifest.json`、`combat-effects-manifest.json`及用户合法取得的ZIP中的许可文件。

已核对的[Creature Pack官方条款](https://iknowkingrabbit.itch.io/heroic-creature-pack)允许在免费及商业项目使用并要求署名，同时禁止原始素材再分发，修改形式再分发须作者明确书面签名许可。[Overworld官方条款](https://iknowkingrabbit.itch.io/heroic-overworld)禁止将ZIP内容整体或部分放在公开服务器，但对作为游戏或类似产品的一部分提供例外；不能把两者概括成同一个开源素材许可证。

Starter、Buildings、Icon和Magic也分别按各自官方页面的游戏／类似产品例外适用；这五包的游戏用途例外不等于把原始或衍生图集授权为开源素材。

**当前发布策略：**公共源码排除原始ZIP、素材PNG、衍生图集、Godot导入缓存和私人源文件；开发者自行从作者官方页面取得相应许可并在本地安装。Starter是免费取得的素材包，也不自动等于允许独立再分发。

游戏成品、PCK、开源项目随附素材和宣传影像分别核验。将PNG放入PCK不自动产生新的授权，也不把PCK加密当作法律许可；涉及修改素材／可提取素材的成品发布，保留向作者确认具体分发形式的步骤。署名是义务之一，不替代再分发授权。

## 3. Godot与原生扩展

[Godot Engine](https://godotengine.org/license/)采用MIT。官方说明允许在游戏文档／credits中链接该许可页；随游戏分发Godot二进制时，需保留相应版权和许可，并核对其第三方组件许可。不能只复制项目自己的MIT然后删掉引擎及依赖的声明。

本项目`native/body_resolver_m94/`和`native/navigation_m99/`分别有自身`LICENSE`，`licenses/godot-cpp-LICENSE.md`保留godot-cpp来源许可。现存本机dylib与历史资格报告不是跨平台发行认证，不能无测试直接视为通用Release附件。

## 4. 音频与旁白

- Kenney三包：本地LICENSE和清单登记CC0；自愿署名，若分发选定样本则随包保留来源与处理清单。它们不是当前私人神经音效许可的替代文件。
- Kokoro旁白：具体音轨、固定模型revision、声音与前端来源随本地合成收据记录。`share-safe`视频仅含该旁白，战斗／统计音轨静音；这个标签只说明音轨隔离，不认证画面、商标或整部视频的全部发布权利。
- Stable Audio 3 / Gemma相关材料：当前项目只取得了本地非商业试听的用户授权，音频包也明确标注本地评估范围。本次不上传`private-materials/`、模型权重或`local-review`视频。不能将此内部限制反说成上游模型法律上禁止一切公开使用；如需扩展，另行核对届时适用条款和用户授权。

当前检阅网页默认加载`local-review`并提供原AVI链接，因此**不能把整个网页／media目录原样公开**。应另外制作只含允许公开附件的宣传页，保留像素作者署名，避免链接私人材料。

## 5. 字体、工具与其他素材

当前`src/presentation/strategic_font.gd`调用系统字体，声明`bundled_font_bytes:0`；不随源码或二进制复制商业系统字体。若选择Noto／思源等可分发字体，应核对实际字体文件及版本、附其许可，不能仅因系统fallback名单出现该名字就宣称已打包或取得许可。

第三方工具、模型和素材包各自的许可不因本项目使用Godot或采用MIT而改变。生成工具辅助产物的来源、参考图和加工链需分别保留；未查明来源的图像、音频和研究截图不进入公开候选。

## 6. 本源码包的安装与状态

- [素材安装说明](docs/ASSET_INSTALLATION.md)列出本地合法安装入口与限制。
- [源码候选状态](docs/RELEASE_STATUS.md)区分静态检查与待执行的干净环境验证。
- [原生源码说明](docs/NATIVE_SOURCE.md)说明本包未启用原生二进制。

本仓库不附开发机审计、私人报告、素材包、模型或历史录像；这些说明不是法律意见。未经核准的第三方内容不因代码采用MIT而可公开。
