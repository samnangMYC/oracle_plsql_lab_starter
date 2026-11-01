@echo off
setlocal
where mvn >nul 2>nul
if errorlevel 1 (
  echo Maven was not found. Install Maven and add mvn to PATH.
  exit /b 1
)
call mvn clean package
if errorlevel 1 exit /b 1
echo Build complete: target\stdcifd-weblogic.war
endlocal
