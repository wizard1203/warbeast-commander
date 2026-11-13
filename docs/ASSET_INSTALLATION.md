# 本地素材安装（BYOA）

源码不附Heroic原始图或衍生图集。作者：Aleksandr Makarov (iknowkingrabbit)。从[CREDITS](../CREDITS.md)的六个官方页面合法取得素材，阅读所购版本的条款。署名不能代替再分发许可。

## 最小Starter

```sh
node tools/install_heroic_starter.mjs "/path/to/HAS Starter Pack.zip"
node tools/install_heroic_starter.mjs --check
```

安装器只处理本地ZIP，不联网、不执行包内代码，验证固定SHA与七张PNG后写入`assets/third_party/heroic_local/`。不要提交此目录。版本不同会拒绝；不要为安装其他版本随意修改哈希。缺Starter时正常游戏显示素材安装提示，不能称为开箱即玩。

## 可选完整Collection

先安装Starter，将以下合法ZIP放入同一目录：

- HAS Overworld 2.1.zip
- HAS Buildings Pack 1.01.zip
- HAS Creature Pack (v.1.4).zip
- HAS IconPack (v.1.2).zip
- HAS Magic Book (1.1).zip

```sh
node tools/install_heroic_collection.mjs --from-dir "/path/to/legally-acquired-zips"
node tools/install_heroic_collection.mjs --check
```

原作者合同元数据保留在`assets/art/heroic/`，像素仍留在用户本地。现有安装器不单独恢复`heroic_world_local`和`heroic_combat_local`额外裁片，也不生成项目原创预烘焙图集。因此最小源码不承诺与开发录像完全相同的美术或性能。不得将本地安装目录上传公开仓库／LFS；成品PCK及修改素材的分发需另行核验。
