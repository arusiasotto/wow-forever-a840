@echo off
rem Forever client lives on the container C: drive so Battle.net Agent can update it.
set "WOWDIR=C:\Program Files (x86)\World of Warcraft"
cd /d "%WOWDIR%\_classic_beta_" || exit /b 1
start "" /wait "WowB-ARM64.exe" -d3d11
