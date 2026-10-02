param([switch]$LlamaCpp)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

docker version *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker no responde: abre Docker Desktop y espera a 'Engine running'." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path ".env")) { Copy-Item ".env.example" ".env" }

$url = if ($LlamaCpp) { "http://llamacpp:8080" } else { "http://host.docker.internal:1234" }
$envText = (Get-Content ".env" -Raw) -replace "(?m)^LOCAL_URL=.*$", "LOCAL_URL=$url"
[IO.File]::WriteAllText("$PSScriptRoot\.env", ($envText -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding $false))

if ($LlamaCpp) {
    docker compose --profile llamacpp up -d --build
} else {
    docker compose --profile llamacpp stop llamacpp *> $null
    docker compose up -d --build
}
if ($LASTEXITCODE -ne 0) { exit 1 }

docker compose exec workspace ia
