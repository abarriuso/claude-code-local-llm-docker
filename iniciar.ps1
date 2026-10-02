# Arranca el entorno de trabajo IA en Docker Desktop (Windows).
# Uso:  powershell -ExecutionPolicy Bypass -File .\iniciar.ps1             (modelo local en LM Studio, Windows)
#       powershell -ExecutionPolicy Bypass -File .\iniciar.ps1 -LlamaCpp   (modelo local en llama.cpp, Docker + GPU NVIDIA)
param([switch]$LlamaCpp)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

docker version *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker no responde. Abre Docker Desktop, espera a 'Engine running' y repite." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Creado .env a partir de .env.example." -ForegroundColor Yellow
}

# Apunta LOCAL_URL al servidor de modelos del modo elegido (se guarda con finales de linea LF)
$url = if ($LlamaCpp) { "http://llamacpp:8080" } else { "http://host.docker.internal:1234" }
$envText = (Get-Content ".env" -Raw) -replace "(?m)^LOCAL_URL=.*$", "LOCAL_URL=$url"
[IO.File]::WriteAllText("$PSScriptRoot\.env", ($envText -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding $false))

if ($LlamaCpp) {
    docker compose --profile llamacpp up -d --build
    if ($LASTEXITCODE -ne 0) { exit 1 }
    Write-Host ""
    Write-Host "llama.cpp arrancado. La primera vez descarga el modelo (puede tardar)." -ForegroundColor Yellow
    Write-Host "Progreso: docker compose logs -f llamacpp" -ForegroundColor Yellow
} else {
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 "http://localhost:1234/v1/models" | Out-Null
        Write-Host "LM Studio responde en el puerto 1234." -ForegroundColor Green
    } catch {
        Write-Host "Aviso: LM Studio no responde en localhost:1234 (Developer -> Start Server)." -ForegroundColor Yellow
        Write-Host "Puedes seguir: las opciones con Claude funcionan igual." -ForegroundColor Yellow
    }
    # Si venia de modo llama.cpp, lo para para liberar la GPU
    docker compose --profile llamacpp stop llamacpp *> $null
    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

Write-Host ""
Write-Host "Listo. Entrando en el menu (para volver mas tarde: docker compose exec workspace ia)" -ForegroundColor Green
docker compose exec workspace ia
