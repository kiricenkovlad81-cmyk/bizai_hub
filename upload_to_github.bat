@echo off
cd /d "%~dp0"
echo === BizAI Hub: upload to GitHub ===
where git >nul 2>nul || (echo Git is not installed. Install it from https://git-scm.com and run this file again. & pause & exit /b 1)
if not exist ".git" git init
echo upload_to_github.bat>> ".git\info\exclude"
git config user.name "kiricenkovlad81-cmyk"
git config user.email "kiricenkovlad81-cmyk@users.noreply.github.com"
git add -A
git commit -m "BizAI Hub: AI order intake for small businesses in Taraz (Flutter: Android, iOS, Windows, macOS, Linux, Web)"
git branch -M main
git remote remove origin 2>nul
git remote add origin https://github.com/kiricenkovlad81-cmyk/bizai_hub.git
echo.
echo If a GitHub sign-in window opens, sign in as kiricenkovlad81-cmyk.
git push -u origin main
echo.
if errorlevel 1 (echo UPLOAD FAILED - send a screenshot of this window to Claude.) else (echo DONE: https://github.com/kiricenkovlad81-cmyk/bizai_hub)
pause
