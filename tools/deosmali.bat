@echo off
cd /d %~dp0
java -jar baksmali-1.4.0.jar -o smalicode/ classes.dex