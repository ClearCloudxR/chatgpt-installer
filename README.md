# ChatGPT Installer (校园网快捷方式生成器)

> **重要说明：这不是 ChatGPT 客户端，与 OpenAI 没有任何关系。**
>
> 本工具生成的桌面快捷方式**只是把 `xmyz.xmedu.cn`（厦门一中校园网）用 ChatGPT 的图标和名称包装起来**，
> 目的是让校园网入口在学生电脑上更容易被找到和点击。
> **它不会连接 OpenAI，不会调用任何 AI 服务，不收集、不上传任何数据。**

---

## 这个项目是做什么的

一个 U 盘绿色小工具：插入 U 盘 → 双击一个 `.bat` → 桌面上生成一个指向校园网的快捷方式。

**为什么需要它？**

- 学生电脑上桌面图标太多，校园网入口藏在收藏夹里容易找不到
- 用 Chrome/Edge 的 `--app=` 模式打开，可以去掉地址栏和标签页，看起来像一个独立软件
- 每次换电脑都要手动建快捷方式太麻烦，所以做成"插上就能装"

**为什么图标是 ChatGPT 的？**

因为目标是让这个入口**显眼、易点**。这是个使用体验上的取舍，**不代表本工具与 OpenAI 有关联**。

---

## 快速使用

### 对于想直接用的人

1. 把整个 `ChatGPT Installer` 文件夹拷到 U 盘根目录
2. 到目标电脑上，双击 `ChatGPT Installer.bat`
3. 桌面出现快捷方式，完成

### 文件说明

| 文件 | 作用 |
|------|------|
| `ChatGPT Installer.bat` | 双击运行的入口 |
| `create_shortcut.ps1` | 实际干活的 PowerShell 脚本 |
| `chatgpt.ico` | 快捷方式用的图标（会被复制到目标电脑本机） |

> ⚠️ 三个文件**必须放在同一个文件夹**里。脚本用 `$PSScriptRoot` 定位自己所在目录，
> 单独把 `.bat` 拷到别处会找不到脚本和图标。

---

## 工作原理

```
双击 .bat
   ↓
调用同目录的 create_shortcut.ps1
   ↓
① 检测浏览器：优先 Chrome → 退回 Edge → 都没有则用系统默认浏览器
② 确定桌面路径：[Environment]::GetFolderPath('Desktop')  ← 当前用户桌面，不需要管理员
③ 把 chatgpt.ico 复制到 %LOCALAPPDATA%\ChatGPT_Shortcut\   ← 防止拔掉 U 盘后图标丢失
④ 用 WScript.Shell 创建 .lnk
⑤ 验证 .lnk 真的生成了，才报告成功
```

### 几个刻意的设计

**用当前用户桌面，不用公共桌面**

`CommonDesktopDirectory`（`C:\Users\Public\Desktop`）需要管理员权限。
普通账户写入会抛 `UnauthorizedAccessException`。本工具用 `GetFolderPath('Desktop')`，
**全程不需要管理员权限**。

**验证后才报告成功**

脚本检查 `.lnk` 是否真的存在，失败会返回非零退出码。
`.bat` 根据退出码显示"成功"或"失败"，**不会盲目打印"安装完成"**。

**失败时窗口不关闭**

`.bat` 结尾是 `pause`，让用户能看到报错信息，而不是窗口一闪而过。

**图标复制到本机**

如果直接引用 U 盘上的图标，拔掉 U 盘后桌面图标会变成白纸。

**BAT 里不用 `chcp`**

`.bat` 用 GBK(936) 编码，PowerShell 输出 UTF-8。
如果在 `.bat` 里强制 `chcp 936`，PowerShell 输出的中文会全部变成乱码。
保持控制台默认代码页即可两边都正常。

---

## 自定义

想改成别的网址？编辑 `create_shortcut.ps1` 开头的配置区：

```powershell
$targetUrl     = 'https://xmyz.xmedu.cn/'   # 改成你的网址
$shortcutName  = 'ChatGPT'                  # 桌面快捷方式的名字
$iconLocalName = 'ChatGPT_Shortcut'         # 图标在本机的存放文件夹
$appMode       = $true                      # $true=无边框应用窗口；$false=普通标签页
```

换图标：把同目录的 `chatgpt.ico` 换成你自己的 `.ico` 文件（保持文件名不变）。

---

## 已知限制

### ❌ 不能插上 U 盘自动运行

这是 **Windows 的系统限制，无解**：

- Windows 7 起，微软为防 Conficker 蠕虫，**从内核层禁用了可移动磁盘的 AutoRun**
- 默认策略 `NoDriveTypeAutoRun = 221`（`0xDD`），第 2 位专门禁用可移动磁盘
- 即使改注册表，Win7 之后 `.bat` 的 `open=` **依然不会执行**

所以 `autorun.inf` 在本项目里**基本是摆设**（它只管 U 盘的卷标和图标显示）。
**用户必须手动双击 `.bat` 一次**，全世界所有 U 盘工具都是这样。

### ⚠️ 依赖 PowerShell

脚本用 `WScript.Shell` COM 对象创建快捷方式。
如果目标电脑的安全软件拦截 `powershell -ExecutionPolicy Bypass`，会失败。
正常情况下脚本会打印红色错误信息。

### ⚠️ 快捷方式不能跨电脑直接复制

`.lnk` 文件里记录的是**绝对路径**（浏览器位置、图标位置）。
直接把桌面的 `.lnk` 拷到别的电脑会变成坏快捷方式（图标变白纸）。

**正确做法是在每台电脑上重新双击 `.bat`**，脚本会自动检测那台机器的路径。
这是本项目存在的核心意义。

### ⚠️ 图标源图质量

`chatgpt.ico` 包含 6 种尺寸（16/32/48/64/128/256），由一张 180×180 的 PNG 生成。
256px 那一档是插值放大，**在超大图标视图下会略微发糊**。桌面常规尺寸没问题。

---

## 免责声明

- 本项目与 **OpenAI 无任何关联**，ChatGPT 名称与图标归 OpenAI 所有
- 图标仅用于个人桌面快捷方式的视觉标识
- 快捷方式指向的 `xmyz.xmedu.cn` 为厦门第一中学官方网站
- 本工具**不收集、不传输、不存储任何用户数据**
- 代码完全公开，可自行审阅全部行为

---

## License

MIT
