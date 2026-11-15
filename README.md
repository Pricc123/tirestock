# 轮胎库存 iOS App

WKWebView 壳工程，打开后加载 https://tire.pricc.fun

已内置：下拉刷新、侧滑返回、电话链接调起拨号、alert/confirm/prompt 桥接、
相机 / 麦克风 / 相册权限（H5 调用 getUserMedia 和 input file 都能用）。

---

## 方案 A：GitHub Actions 免费云编译出 ipa（不需要 Mac，0 成本）

公开仓库的 macOS 构建时长完全免费，每月额度足够用几百次。

### 1. 注册 GitHub
打开 https://github.com 注册一个账号（免费）。

### 2. 建一个仓库
右上角 `+` → New repository → 名字随便（如 `tirestock`）→ 选 **Public** → Create repository。

### 3. 上传工程
在新建的仓库页面点 `uploading an existing file`，
把本文件夹里的**所有内容**（`TireStock/`、`TireStock.xcodeproj/`、`.github/`、`README.md`）拖进去，
点 `Commit changes`。

> 注意：`.github` 是隐藏文件夹，Mac 上按 `Cmd+Shift+.` 显示隐藏文件；
> Windows 上在文件夹选项里勾选「显示隐藏的文件、文件夹和驱动器」。
> 这个文件夹里放的就是自动编译脚本，**必须上传**，否则不会自动打包。

### 4. 触发编译
仓库顶部点 `Actions` → 左边选 `Build unsigned IPA` → 右边 `Run workflow` → 绿色按钮。
大约 3~5 分钟跑完，出现绿勾。

### 5. 下载 ipa
点进这次运行 → 页面底部 `Artifacts` → 下载 `TireStock-unsigned-ipa`。
解压得到 `TireStock-unsigned.ipa`（**未签名**，必须自己签才能装）。

---

## 方案 B：Mac 本地用 Xcode 编译

1. 双击 `TireStock.xcodeproj` 打开
2. 选中 TARGETS → TireStock → Signing & Capabilities → Team 选你的账号，
   Bundle Identifier 改成自己的（如 `com.你的名字.tirestock`）
3. 顶部设备选 `Any iOS Device (arm64)`
4. Product → Archive → Distribute App → Ad Hoc / Development → Export 出 ipa

---

## 签名安装（免费 Apple ID 也行）

拿到 ipa 后，用 **Sideloadly**（Windows / Mac 都有，免费）：
https://sideloadly.io

1. 电脑装 iTunes（Windows 版，用于驱动）
2. iPhone 用数据线连电脑，手机上点「信任」
3. 打开 Sideloadly，把 ipa 拖进去
4. Apple ID 填你的普通 Apple ID（不用开发者账号）
5. 点 Start，输入 Apple ID 密码（用于生成签名证书，只本地用）
6. 装完手机上：设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID

**免费 Apple ID 的限制**：App 7 天后过期，重新用 Sideloadly 装一次即可续期；
最多同时装 3 个自签 App。想要一年有效期需要 99 美元/年开发者账号。

---

## 其他免费/低成本路子

- **TrollStore**：iOS 14.0~16.6.1 部分版本支持，免签名永久安装，但要看你的系统版本
- **AltStore**：电脑端常驻，自动 7 天续签，不用手动重装
- **Codemagic**：免费 500 分钟/月 macOS 构建，也能出 ipa

---

## 工程打不开时的备用方案

新建一个 iOS App 项目（Interface 选 SwiftUI），把 `TireStockApp.swift` 和
`ContentView.swift` 的内容粘进去，图标换成 `Assets.xcassets/AppIcon.appiconset/icon1024.png`。
