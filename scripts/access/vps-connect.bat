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

echo [INFO] Conectando a VPS: %VPS_USER%@%VPS_IP%...

if defined SSH_KEY_PATH (
    ssh -i "%SSH_KEY_PATH%" %VPS_USER%@%VPS_IP%
) else (
    ssh %VPS_USER%@%VPS_IP%
)

pause
