@echo off
chcp 65001 >nul
title AI Toolkit Map - 一键提交并推送
cd /d "%~dp0"

setlocal enabledelayedexpansion

REM ---- 提交信息：支持传参，缺省用当前时间 ----
if "%~1"=="" (
  for /f "tokens=1-3 delims=/: " %%a in ("%date% %time%") do set MSG=auto commit %%~na
  if "!MSG!"=="" set MSG=auto commit
) else (
  set MSG=%*
)

echo ========================================
echo  [1/3] git add .
echo ========================================
git add .
if errorlevel 1 ( echo [失败] git add 出错 & pause & exit /b 1 )

echo.
echo ========================================
echo  [2/3] git commit -m "!MSG!"
echo ========================================
git commit -m "!MSG!"
if errorlevel 1 (
  echo.
  echo [提示] 没有可提交的更改，或提交失败。
  echo        若无更改可直接 push。
)

echo.
echo ========================================
echo  [3/3] 一键 push 到 GitHub + Gitee
echo ========================================
git push origin
if errorlevel 1 (
  echo.
  echo [失败] push 未全部成功，请检查网络或账号凭据。
  echo        可手动执行: git push origin
  pause
  exit /b 1
)

echo.
echo ========================================
echo  ✔ 已同步到 GitHub 与 Gitee 两个仓库
echo ========================================
pause
