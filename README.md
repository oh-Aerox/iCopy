# iCopy

给 Apple Silicon Mac 用的轻量剪贴板管理器。菜单栏常驻，`⌘⇧V` 从当前屏幕底部以方块平铺唤起。

## 使用

1. 运行 `scripts/build.sh`，得到 `dist/iCopy.app`
2. 打开 `iCopy.app`（菜单栏会出现剪贴板图标）
3. 复制文本或图片后，按 `⌘⇧V` 唤起底部方块
4. 搜索、点击方块即可粘贴到原先光标处；齿轮里可设置保留 50 / 100 / 200 条，以及过期时间

首次自动粘贴时，系统会请求「辅助功能」权限：在列表中打开 **iCopy** 后，请从菜单栏退出并重新打开应用，之后不会再反复弹窗。若只打开开关却不重启，系统仍会认为当前进程未授权。

## 生成 DMG

需要 macOS 自带的 `hdiutil`，以及已安装的 Swift 命令行工具。只打 arm64（Apple Silicon）。

一条命令（先编 `.app`，再打压缩镜像）：

```bash
./scripts/dmg.sh
```

完成后得到 `dist/iCopy.dmg`。

手动分步也可以：

```bash
# 1. 编译并打包应用
./scripts/build.sh

# 2. 准备镜像内容：应用 + Applications 快捷方式，方便拖进「应用程序」
rm -rf dist/dmg-stage
mkdir -p dist/dmg-stage
cp -R dist/iCopy.app dist/dmg-stage/iCopy.app
ln -s /Applications dist/dmg-stage/Applications

# 3. 生成 UDZO 压缩只读 DMG
hdiutil create \
  -volname iCopy \
  -srcfolder dist/dmg-stage \
  -ov \
  -format UDZO \
  dist/iCopy.dmg

# 4. 删除临时目录
rm -rf dist/dmg-stage
```

安装：双击 `iCopy.dmg`，把 `iCopy` 拖到 `Applications`，再从启动台或应用程序文件夹打开。

## 开发

```bash
swift run
```

需要 macOS 14+ 与 Apple Silicon。成品约 330KB，不捆绑 Chromium / Node / Rust 运行时。数据存在 `~/Library/Application Support/iCopy`。
