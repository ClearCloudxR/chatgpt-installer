@echo off
setlocal
title ChatGPT 快捷方式安装

rem 不要用 chcp 强制代码页：那会让 PowerShell 输出的中文变成乱码。
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create_shortcut.ps1"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo [成功] 桌面已创建 ChatGPT 快捷方式。
) else (
    echo [失败] 安装未完成，错误码：%RC%
    echo 请把上面的红色文字截图反馈。
)

echo.
echo 按任意键关闭本窗口...
pause >nul
endlocal