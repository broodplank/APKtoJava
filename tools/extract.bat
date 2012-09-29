@echo off
cd /d %~dp0
move %1 %1.zip
7za.exe x -y %1 *.dex
pause