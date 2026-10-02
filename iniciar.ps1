param([switch]$LlamaCpp)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

function Ok($m)    { Write-Host "  [ok] $m" -ForegroundColor Green }
function Aviso($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Fallo($m) { Write-Host "  [x]  $m" -ForegroundColor Red }

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Fallo "Docker no responde."
    Write-Host "       Abre Docker Desktop, espera a 'Engine running' y vuelve a ejecutar este script."
    exit 1
}
Ok "Docker"

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env" -ErrorAction Stop
    Ok ".env creado"
}

$url = if ($LlamaCpp) { "http://llamacpp:8080" } else { "http://host.docker.internal:1234" }
$envText = (Get-Content ".env" -Raw) -replace "(?m)^LOCAL_URL=.*$", "LOCAL_URL=$url"
[IO.File]::WriteAllText("$PSScriptRoot\.env", ($envText -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding $false))

if ($LlamaCpp) {
    docker compose --profile llamacpp up -d --build
    if ($LASTEXITCODE -ne 0) { Fallo "No se pudo arrancar. Revisa que Docker vea la GPU NVIDIA."; exit 1 }
    Ok "llama.cpp arrancado"
    Aviso "El primer arranque descarga el modelo. Progreso: docker compose logs -f llamacpp"
} else {
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop "http://localhost:1234/v1/models" | Out-Null
        Ok "LM Studio"
    } catch {
        Aviso "LM Studio no responde (Developer -> Start Server). Las opciones con Claude funcionan igual."
    }
    docker compose --profile llamacpp stop llamacpp *> $null
    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) { Fallo "No se pudo arrancar el entorno."; exit 1 }
}
Ok "Entorno listo. Para volver a entrar: docker compose exec workspace ia"

docker compose exec workspace ia
