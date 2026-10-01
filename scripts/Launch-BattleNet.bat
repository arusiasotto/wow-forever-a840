@echo off
rem Same GameNative container as WoW. Do not use a separate Battle.net library card.
cd /d "G:\Battle.net" || exit /b 1
start "" /wait "Battle.net Launcher.exe"
