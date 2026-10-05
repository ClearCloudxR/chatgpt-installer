# ============================================================
#  ChatGPT 桌面快捷方式安装脚本
#  用法：由同目录下的 BAT 调用，或右键“使用 PowerShell 运行”
# ============================================================

$ErrorActionPreference = 'Stop'

# ---------- 可修改的配置 ----------
$targetUrl     = 'https://xmyz.xmedu.cn/'
$shortcutName  = 'ChatGPT'
$iconLocalName = 'ChatGPT_Shortcut'   # 图标在本机的存放文件夹名
$appMode       = $true      # $true = 用--app无边框窗口打开（像独立软件）；$false = 普通标签页
# ----------------------------------

function Write-Info { param($m) Write-Host $m }
function Write-OK   { param($m) Write-Host $m -ForegroundColor Green }
function Write-Warn2{ param($m) Write-Host $m -ForegroundColor Yellow }

Write-Info '============================================'
Write-Info '   ChatGPT 快捷方式安装程序'
Write-Info '============================================'
Write-Info ''

# ---- 1. 找浏览器：优先 Chrome，找不到就用 Edge ----
$browserExe = $null
$candidates = @(
    @{ Name = 'Chrome'; Paths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )},
    @{ Name = 'Edge'; Paths = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
    )}
)

foreach ($b in $candidates) {
    foreach ($p in $b.Paths) {
        if ($p -and (Test-Path -LiteralPath $p)) {
            $browserExe = $p
            Write-Info "已找到浏览器：$($b.Name)"
            break
        }
    }
    if ($browserExe) { break }
}

if (-not $browserExe) {
    # 两个常见浏览器都没装：退回系统默认浏览器，至少保证快捷方式能打开网页
    Write-Warn2 '未找到 Chrome 或 Edge，将使用系统默认浏览器打开。'
    $browserExe  = 'explorer.exe'
    $appMode     = $false
}

# ---- 2. 确定桌面路径（当前用户桌面，不需要管理员权限）----
$desktopPath = [Environment]::GetFolderPath('Desktop')
if ([string]::IsNullOrWhiteSpace($desktopPath) -or -not (Test-Path -LiteralPath $desktopPath)) {
    $desktopPath = Join-Path $env:USERPROFILE 'Desktop'
}
if (-not (Test-Path -LiteralPath $desktopPath)) {
    throw "找不到桌面文件夹：$desktopPath"
}
Write-Info "桌面位置：$desktopPath"

# ---- 3. 把图标复制到本机，避免拔掉 U 盘后图标变白纸 ----
$iconDir  = Join-Path $env:LOCALAPPDATA $iconLocalName
$iconDest = Join-Path $iconDir 'chatgpt.ico'
$iconReady = $false

$iconSource = Join-Path $PSScriptRoot 'chatgpt.ico'
if (Test-Path -LiteralPath $iconSource) {
    try {
        if (-not (Test-Path -LiteralPath $iconDir)) {
            New-Item -ItemType Directory -Path $iconDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $iconSource -Destination $iconDest -Force
        $iconReady = $true
        Write-Info '图标已复制到本机。'
    } catch {
        Write-Warn2 "图标复制失败，将使用浏览器自带图标。（$($_.Exception.Message)）"
    }
} else {
    Write-Warn2 'U 盘里没有 chatgpt.ico，将使用浏览器自带图标。'
}

# ---- 4. 创建 .lnk 快捷方式 ----
$shortcutPath = Join-Path $desktopPath "$shortcutName.lnk"

if ($appMode) {
    $arguments = "--app=$targetUrl"
} else {
    $arguments = $targetUrl
}

try {
    $wsh      = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($shortcutPath)
    $shortcut.TargetPath       = $browserExe
    $shortcut.Arguments        = $arguments
    $shortcut.Description      = $shortcutName
    $shortcut.WorkingDirectory = Split-Path -Parent $browserExe
    if ($iconReady) {
        $shortcut.IconLocation = "$iconDest,0"
    }
    $shortcut.Save()
} catch {
    Write-Host ''
    Write-Host '创建快捷方式失败！' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ---- 5. 验证结果 ----
if (Test-Path -LiteralPath $shortcutPath) {
    Write-Host ''
    Write-OK '============================================'
    Write-OK '   安装完成！'
    Write-OK '============================================'
    Write-Info "快捷方式位置：$shortcutPath"
    Write-Info "打开网址：$targetUrl"
    Write-Info ''
    Write-Info '现在可以拔掉 U 盘，双击桌面上的 ChatGPT 图标即可使用。'
    exit 0
} else {
    Write-Host ''
    Write-Host '脚本执行了，但桌面上没有生成快捷方式。' -ForegroundColor Red
    Write-Host '可能是安全软件拦截了快捷方式创建，请暂时关闭后重试。' -ForegroundColor Red
    exit 1
}