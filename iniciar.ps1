param([switch]$LlamaCpp)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

function Ok($m)    { Write-Host "  [ok] $m" -ForegroundColor Green }
function Aviso($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Fallo($m) { Write-Host "  [x]  $m" -ForegroundColor Red }

function LMStudioActivo {
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop "http://localhost:1234/v1/models" | Out-Null
        return $true
    } catch { return $false }
}

$osType = docker info --format "{{.OSType}}" 2> $null
if ($LASTEXITCODE -ne 0) {
    Fallo "Docker no responde."
    Write-Host "       Abre Docker Desktop, espera a 'Engine running' y vuelve a ejecutar este script."
    exit 1
}
if ($osType -ne "linux") {
    Fallo "Docker esta en modo contenedores de Windows."
    Write-Host "       Clic derecho en el icono de Docker -> 'Switch to Linux containers'."
    exit 1
}
Ok "Docker"

$envPath = Join-Path $PSScriptRoot ".env"
$utf8 = New-Object Text.UTF8Encoding $false
if (-not (Test-Path $envPath)) {
    Copy-Item (Join-Path $PSScriptRoot ".env.example") $envPath -ErrorAction Stop
    Ok ".env creado"
}

$url = if ($LlamaCpp) { "http://llamacpp:8080" } else { "http://host.docker.internal:1234" }
$envText = [IO.File]::ReadAllText($envPath, $utf8) -replace "`r`n", "`n"
if ($envText -match "(?m)^LOCAL_URL=") {
    $envText = $envText -replace "(?m)^LOCAL_URL=.*$", "LOCAL_URL=$url"
} else {
    if ($envText.Length -gt 0 -and -not $envText.EndsWith("`n")) { $envText += "`n" }
    $envText += "LOCAL_URL=$url`n"
}
[IO.File]::WriteAllText($envPath, $envText, $utf8)

if ($LlamaCpp) {
    if (LMStudioActivo) { Aviso "LM Studio tambien esta activo y puede ocupar memoria de la GPU." }
    docker compose --profile llamacpp up -d --build
    if ($LASTEXITCODE -ne 0) {
        Fallo "No se pudo arrancar. Revisa el error de arriba (GPU NVIDIA visible en Docker, puerto ocupado...)."
        exit 1
    }
    Ok "llama.cpp arrancado"
    Aviso "El primer arranque descarga el modelo. Progreso: docker compose logs -f llamacpp"
} else {
    if (LMStudioActivo) { Ok "LM Studio" }
    else { Aviso "LM Studio no responde (Developer -> Start Server). Las opciones con Claude funcionan igual." }
    docker compose --profile llamacpp stop llamacpp *> $null
    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) {
        Fallo "No se pudo arrancar el entorno. Revisa el error de arriba (p. ej. puerto ocupado)."
        exit 1
    }
}
Ok "Entorno listo. Para volver a entrar: docker compose exec workspace ia"

docker compose exec workspace ia
