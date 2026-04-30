@echo off
setlocal enabledelayedexpansion

:: Verifica se o arquivo .env.access existe
if not exist "%~dp0.env.access" (
    echo [ERRO] Arquivo .env.access nao encontrado!
    echo Por favor, copie .env.access.example para .env.access e preencha os dados.
    pause
    exit /b 1
)

:: Carrega variaveis do .env.access
for /f "tokens=1,2 delims==" %%a in (%~dp0.env.access) do (
    set %%a=%%b
)

echo [INFO] Abrindo Dashboard do EasyPanel...
echo [INFO] URL: %EASYPANEL_URL%
echo [INFO] Login: %EASYPANEL_EMAIL%

start %EASYPANEL_URL%

echo.
echo Pressione qualquer tecla para fechar...
pause > nul
