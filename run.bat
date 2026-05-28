@echo off
REM Script para ejecutar Flutter Tweeter en Windows
REM Uso: run.bat [opción]
REM Opciones:
REM   web      - Ejecutar en navegador web
REM   android  - Compilar APK para Android
REM   help     - Mostrar esta ayuda

setlocal enabledelayedexpansion

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

REM Colors para output
set "GREEN=[32m"
set "BLUE=[34m"
set "YELLOW=[33m"
set "NC=[0m"

REM Función para mostrar encabezado
REM echo %BLUE%Encabezado...%NC%

echo.
echo Flutter Tweeter - Script de ejecución
echo.

if "%~1"=="" goto :help
if "%~1"=="help" goto :help
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="web" goto :run_web
if "%~1"=="android" goto :build_android
if "%~1"=="analyze" goto :analyze_code
if "%~1"=="deps" goto :get_dependencies

echo Opción desconocida: %~1
goto :help

:get_dependencies
echo.
echo Obteniendo dependencias...
flutter pub get
echo.
echo [32m✓ Dependencias obtenidas[0m
echo.
goto :end

:analyze_code
echo.
echo Analizando código...
flutter analyze
echo.
echo [32m✓ Análisis completado[0m
echo.
goto :end

:run_web
echo.
echo Ejecutando en navegador web...
call :get_dependencies
flutter run -d chrome
goto :end

:build_android
echo.
echo Compilando APK para Android...
call :get_dependencies
flutter build apk --release
echo.
echo [32m✓ APK compilado en: build\app\outputs\apk\release\app-release.apk[0m
echo.
goto :end

:help
echo Uso:
echo    run.bat [opción]
echo.
echo Opciones:
echo    web       Ejecutar en navegador web
echo    android   Compilar APK para Android
echo    analyze   Analizar código Dart
echo    deps      Obtener dependencias
echo    help      Mostrar esta ayuda
echo.
echo Ejemplos:
echo    run.bat web
echo    run.bat android
echo    run.bat analyze
echo.

:end
endlocal
