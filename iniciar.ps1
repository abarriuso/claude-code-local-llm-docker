param([switch]$LlamaCpp)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
try { $Host.UI.RawUI.WindowTitle = "claude-code-local-llm-docker" } catch { }
$Moderna = [bool]$env:WT_SESSION
$Profiles = if ($LlamaCpp) { @("--profile", "llamacpp") } else { @() }

# docker.exe deja la consola en modo "entrada VT" al salir y Read-Host empieza a
# recibir secuencias de escape (teclas, cambios de foco) como si fueran texto.
# Por eso docker nunca lee de la consola ($null | docker ... o -RedirectStandardInput)
# y antes de cada lectura se restaura el modo original de la consola.
$ModoEntrada = $null
try {
    Add-Type -Namespace Win32 -Name Consola -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
'@
    $m = [uint32]0
    if ([Win32.Consola]::GetConsoleMode([Win32.Consola]::GetStdHandle(-10), [ref]$m)) { $ModoEntrada = $m }
} catch { }

function Leer($texto) {
    if ($null -ne $ModoEntrada) {
        try { [void][Win32.Consola]::SetConsoleMode([Win32.Consola]::GetStdHandle(-10), $ModoEntrada) } catch { }
    }
    try { $Host.UI.RawUI.FlushInputBuffer() } catch { }
    return Read-Host $texto
}

function Ok($m)    { Write-Host "   OK  " -ForegroundColor Black -BackgroundColor Green -NoNewline; Write-Host "  $m" }
function Aviso($m) { Write-Host "   !!  " -ForegroundColor Black -BackgroundColor Yellow -NoNewline; Write-Host "  $m" -ForegroundColor Yellow }
function Fallo($m) { Write-Host "  ERROR" -ForegroundColor White -BackgroundColor Red -NoNewline; Write-Host "  $m" -ForegroundColor Red }
function Paso($m)  { Write-Host ""; Write-Host "   $m" -ForegroundColor White }
function Nota($m)  { Write-Host "         $m" -ForegroundColor DarkGray }

function Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │" -ForegroundColor DarkCyan -NoNewline
    Write-Host "   claude-code-local-llm-docker                           " -ForegroundColor White -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "  │" -ForegroundColor DarkCyan -NoNewline
    Write-Host "   Entorno aislado con Claude Code, OpenCode y modelos    " -ForegroundColor DarkGray -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "  │" -ForegroundColor DarkCyan -NoNewline
    Write-Host "   locales, protegido por un cortafuegos de salida.       " -ForegroundColor DarkGray -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "  └──────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
}

function Girar($i) {
    $f = if ($Moderna) { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" } else { "|", "/", "-", "\" }
    return $f[$i % $f.Count]
}

function Limpiar { Write-Host ("`r" + (" " * 78) + "`r") -NoNewline }

function LMStudioActivo {
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop "http://localhost:1234/v1/models" | Out-Null
        return $true
    } catch { return $false }
}

function Esperar($texto, [string[]]$argumentos) {
    $log = Join-Path $env:TEMP "claude-code-local-llm-docker.log"
    $err = "$log.err"
    $vacio = "$log.in"
    Set-Content $vacio "" -NoNewline
    $p = Start-Process docker -ArgumentList $argumentos -NoNewWindow -PassThru `
        -RedirectStandardInput $vacio -RedirectStandardOutput $log -RedirectStandardError $err
    $null = $p.Handle
    $reloj = [Diagnostics.Stopwatch]::StartNew()
    $i = 0
    while (-not $p.HasExited) {
        Write-Host ("`r   {0}    {1}  {2:mm\:ss}" -f (Girar $i), $texto, $reloj.Elapsed) -ForegroundColor Cyan -NoNewline
        Start-Sleep -Milliseconds 120
        $i++
    }
    $p.WaitForExit()
    Limpiar
    if ($p.ExitCode -ne 0) {
        Fallo $texto
        Nota "Últimas líneas del registro:"
        Get-Content $log, $err -ErrorAction SilentlyContinue | Select-Object -Last 25 | ForEach-Object { Nota "  $_" }
        return $false
    }
    Ok ("{0}  ({1:mm\:ss})" -f $texto, $reloj.Elapsed)
    return $true
}

function Abrir($titulo, [string[]]$comando) {
    $exec = @("compose") + $Profiles + @("exec", "-u", "node", "workspace") + $comando
    if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
        & wt.exe -w 0 new-tab --title $titulo -d $PSScriptRoot docker @exec
        Ok "$titulo abierto en una pestaña nueva de esta ventana"
    } else {
        Start-Process docker -ArgumentList $exec -WorkingDirectory $PSScriptRoot
        Ok "$titulo abierto en una ventana nueva"
        Nota "Con Windows Terminal se abriría como pestaña: https://aka.ms/terminal"
    }
    Start-Sleep -Seconds 2
}

function Opcion($n, $titulo, $desc) {
    Write-Host "     $n  " -ForegroundColor Cyan -NoNewline
    Write-Host $titulo.PadRight(22) -NoNewline
    Write-Host $desc -ForegroundColor DarkGray
}

function Menu {
    while ($true) {
        Banner
        Write-Host ""
        Write-Host "   Comprobando el estado..." -ForegroundColor DarkGray -NoNewline
        $estado = ($null | docker compose @Profiles exec -T -u node workspace ia --estado 2> $null) -split "\|"
        Limpiar
        $modelo = if ($estado.Count -ge 1 -and $estado[0]) { $estado[0] } else { "desconocido" }
        $api    = if ($estado.Count -ge 2 -and $estado[1]) { $estado[1] } else { "desconocido" }
        $hayModelo = $modelo -notin @("sin servidor", "sin modelo cargado", "desconocido")
        $hayApi = $api -eq "configurada"

        Write-Host "   Modelo local    " -ForegroundColor DarkGray -NoNewline
        Write-Host $modelo -ForegroundColor $(if ($hayModelo) { "Green" } else { "Yellow" })
        Write-Host "   API Anthropic   " -ForegroundColor DarkGray -NoNewline
        Write-Host $api -ForegroundColor $(if ($hayApi) { "Green" } else { "DarkGray" })
        Write-Host "   Proyectos       " -ForegroundColor DarkGray -NoNewline
        Write-Host "/workspace (clónalos desde la Terminal, opción 6)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   CLAUDE CODE" -ForegroundColor DarkCyan
        Opcion 1 "Suscripción Claude" "Con tu cuenta Pro, Max o Team. La 1ª vez pide iniciar sesión"
        Opcion 2 "API Anthropic"      "Pago por uso. Necesita ANTHROPIC_API_KEY en .env"
        Write-Host ""
        Write-Host "   OPENCODE" -ForegroundColor DarkCyan
        Opcion 3 "Modelo local"       "Gratis. El código no sale de tu PC"
        Opcion 4 "API Anthropic"      "Pago por uso. Necesita ANTHROPIC_API_KEY en .env"
        Write-Host ""
        Write-Host "   OTROS" -ForegroundColor DarkCyan
        Opcion 5 "Modelos locales"    "Lista los modelos disponibles en LM Studio o llama.cpp"
        Opcion 6 "Terminal"           "Línea de comandos del entorno: git, gh, npm..."
        Opcion 7 "Parar el entorno"   "Apaga los contenedores. Proyectos y sesiones se conservan"
        Opcion 0 "Salir"              "Cierra este menú. El entorno sigue encendido"
        Write-Host ""
        Nota "Cada herramienta se abre en una pestaña nueva y este menú sigue aquí,"
        Nota "así puedes usar varias a la vez."
        Write-Host ""
        $op = Leer "   Elige una opción y pulsa Enter"
        if ($null -eq $op) { return }
        if ($op.Trim() -eq "") { continue }

        switch ($op.Trim()) {
            "1" { Abrir "Claude Code" @("ia", "1") }
            "2" {
                if ($hayApi) { Abrir "Claude Code (API)" @("ia", "2") }
                else { Esperar-Tecla "Falta la clave de API" "Añade ANTHROPIC_API_KEY=tu-clave en el archivo .env de esta carpeta y vuelve a ejecutar iniciar.cmd." }
            }
            "3" {
                if ($hayModelo) { Abrir "OpenCode (local)" @("ia", "3") }
                elseif ($LlamaCpp) { Esperar-Tecla "El modelo local aún no está listo" "llama.cpp puede estar descargando el modelo. Míralo con: docker compose logs -f llamacpp" }
                else { Esperar-Tecla "No hay modelo local" "Abre LM Studio, carga un modelo y pulsa Developer -> Start Server. Después vuelve a este menú." }
            }
            "4" {
                if ($hayApi) { Abrir "OpenCode (API)" @("ia", "4") }
                else { Esperar-Tecla "Falta la clave de API" "Añade ANTHROPIC_API_KEY=tu-clave en el archivo .env de esta carpeta y vuelve a ejecutar iniciar.cmd." }
            }
            "5" {
                Paso "Modelos disponibles"
                $null | docker compose @Profiles exec -T -u node workspace ia 5 | ForEach-Object { Nota $_ }
                Write-Host ""
                Leer "   Pulsa Enter para volver al menú" | Out-Null
            }
            "6" { Abrir "Terminal" @("bash") }
            "7" {
                Paso "Parando el entorno..."
                $null | docker compose --profile llamacpp stop *> $null
                Ok "Entorno parado. Para volver a usarlo, ejecuta iniciar.cmd"
                return
            }
            "0" {
                Write-Host ""
                Nota "El entorno sigue encendido. Para volver al menú, ejecuta iniciar.cmd"
                return
            }
            default { Esperar-Tecla "Opción no válida: '$op'" "Escribe un número del 0 al 7 y pulsa Enter." }
        }
    }
}

function Esperar-Tecla($titulo, $detalle) {
    Write-Host ""
    Aviso $titulo
    Nota $detalle
    Write-Host ""
    $r = Leer "   Pulsa Enter para volver al menú"
    if ($null -eq $r) { exit 0 }
}

Banner

Paso "1/4  Comprobando la instalación"
if (-not (Test-Path (Join-Path $PSScriptRoot "docker-compose.yml"))) {
    Fallo "Faltan archivos junto a este script"
    Nota "Parece que lo has abierto desde dentro del ZIP sin extraerlo."
    Nota "Clic derecho en el ZIP -> Extraer todo, y ejecuta iniciar.cmd desde la carpeta extraída."
    exit 1
}
Ok "Archivos del proyecto"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fallo "Docker no está instalado (o esta terminal no lo encuentra)"
    Nota "Instálalo desde https://www.docker.com/products/docker-desktop/"
    Nota "Si acabas de instalarlo, reinicia el ordenador y vuelve a ejecutar iniciar.cmd."
    exit 1
}
Ok "Docker instalado"

Paso "2/4  Comprobando Docker Desktop"
$osType = $null | docker info --format "{{.OSType}}" 2> $null
if ($LASTEXITCODE -ne 0) {
    $exe = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
    if (Test-Path $exe) {
        Nota "Docker Desktop no está abierto. Abriéndolo..."
        Nota "La primera vez puede tardar un par de minutos."
        Start-Process $exe
        $reloj = [Diagnostics.Stopwatch]::StartNew()
        $i = 0
        do {
            Write-Host ("`r   {0}    Esperando a Docker Desktop  {1:mm\:ss}" -f (Girar $i), $reloj.Elapsed) -ForegroundColor Cyan -NoNewline
            Start-Sleep -Seconds 2
            $i++
            $osType = $null | docker info --format "{{.OSType}}" 2> $null
        } while ($LASTEXITCODE -ne 0 -and $reloj.Elapsed.TotalSeconds -lt 240)
        Limpiar
    }
    if ($LASTEXITCODE -ne 0) {
        Fallo "Docker Desktop no responde"
        Nota "Ábrelo desde el menú Inicio y espera a que abajo a la izquierda ponga 'Engine running'."
        Nota "Si muestra un error de virtualización o de WSL, consulta INSTALACION.md (Problemas de instalación)."
        exit 1
    }
}
if ($osType -ne "linux") {
    Fallo "Docker está en modo 'contenedores de Windows'"
    Nota "Clic derecho en el icono de Docker (junto al reloj) -> 'Switch to Linux containers'."
    exit 1
}
Ok "Docker Desktop en marcha"

Paso "3/4  Preparando la configuración"
$envPath = Join-Path $PSScriptRoot ".env"
$utf8 = New-Object Text.UTF8Encoding $false
if (-not (Test-Path $envPath)) {
    Copy-Item (Join-Path $PSScriptRoot ".env.example") $envPath -ErrorAction Stop
    Ok "Archivo de configuración creado (.env)"
    Nota "Ahí puedes poner tu clave de API, tu nombre para git y más. Ver MANUAL.md."
} else {
    Ok "Archivo de configuración (.env)"
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
    Ok "Modelo local: llama.cpp (dentro de Docker)"
    if (LMStudioActivo) { Aviso "LM Studio también está abierto y puede quitarle memoria de la GPU a llama.cpp" }
} else {
    if (LMStudioActivo) { Ok "Modelo local: LM Studio" }
    else {
        Aviso "LM Studio no responde. Claude Code funciona igual; solo afecta a la opción 3."
        Nota "Para usar un modelo local: abre LM Studio, carga un modelo y pulsa Developer -> Start Server."
    }
    $null | docker compose --profile llamacpp stop llamacpp *> $null
}

Paso "4/4  Arrancando el entorno"
Nota "Construye la imagen, arranca el contenedor y activa el cortafuegos."
Nota "La primera vez descarga cerca de 1 GB y puede tardar 5-10 minutos. Después, segundos."
Write-Host ""
$up = @("compose") + $Profiles + @("up", "-d", "--build", "--wait")
if (-not (Esperar "Arrancando" $up)) {
    Write-Host ""
    Nota "Causas habituales: un puerto ocupado (3000, 5173, 8080), sin conexión a internet"
    Nota "o, con llama.cpp, que Docker no vea la tarjeta gráfica NVIDIA."
    Nota "Registro completo: docker compose logs workspace"
    exit 1
}
Ok "Entorno en marcha con el cortafuegos activo"
if ($LlamaCpp) { Nota "llama.cpp descarga el modelo en el primer arranque: docker compose logs -f llamacpp" }

Start-Sleep -Seconds 2
Menu
