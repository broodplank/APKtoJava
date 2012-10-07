@echo off
cd /d %~dp0
copy %1 %1.zip
7za.exe x -y %1.zip *.dex
