@echo off
cd /d %~dp0
java -jar baksmali-1.3.2.jar -o smalicode/ classes.dex