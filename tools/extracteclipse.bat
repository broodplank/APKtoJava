@echo off
cd /d %~dp0
7za.exe x -y -o%1\eclipseproject eclipseproject.zip * 
