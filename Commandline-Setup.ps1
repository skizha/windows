<#
.SYNOPSIS
    Sets up PowerShell with Oh My Posh (gruvbox theme), Terminal-Icons, and PSReadLine.

.DESCRIPTION
    Installs Oh My Posh, CaskaydiaCove Nerd Font, Terminal-Icons, the gruvbox theme,
    and writes a PowerShell profile. Safe to re-run — skips anything already installed.

.NOTES
    Run once in a new PowerShell 7 window:
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
        .\Setup-PowerShell.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step  { param([string]$m) Write-Host "`n>>> $m" -ForegroundColor Cyan }
function Write-OK    { param([string]$m) Write-Host "    OK   $m" -ForegroundColor Green }
function Write-Skip  { param([string]$m) Write-Host "    SKIP $m (already present)" -ForegroundColor Yellow }
function Write-Fail  { param([string]$m) Write-Host "    FAIL $m" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# 1. winget
# ---------------------------------------------------------------------------
Write-Step "Checking winget"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Fail "winget not found. Install 'App Installer' from the Microsoft Store, then re-run."
    exit 1
}
Write-OK "winget available"

# ---------------------------------------------------------------------------
# 2. Oh My Posh
# ---------------------------------------------------------------------------
Write-Step "Installing Oh My Posh"
$ompInstalled = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue)

if (-not $ompInstalled) {
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements --silent
    # Reload PATH so oh-my-posh is reachable in the same session
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-OK "Oh My Posh installed"
} else {
    Write-Skip "Oh My Posh"
}

# Confirm binary is reachable before continuing
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Fail "oh-my-posh still not in PATH. Open a new PowerShell window and re-run the script."
    exit 1
}

# ---------------------------------------------------------------------------
# 3. CaskaydiaCove Nerd Font
# ---------------------------------------------------------------------------
Write-Step "Installing CaskaydiaCove Nerd Font"
oh-my-posh font install CascadiaCode --headless
Write-OK "Font installed (set 'CaskaydiaCove NF' in Windows Terminal settings)"

# ---------------------------------------------------------------------------
# 4. Terminal-Icons
# ---------------------------------------------------------------------------
Write-Step "Installing Terminal-Icons"
if (Get-Module -ListAvailable Terminal-Icons -ErrorAction SilentlyContinue) {
    Write-Skip "Terminal-Icons"
} else {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force -Scope CurrentUser
    Write-OK "Terminal-Icons installed"
}

# ---------------------------------------------------------------------------
# 5. gruvbox theme
# ---------------------------------------------------------------------------
Write-Step "Setting up gruvbox theme"
$themesDir = "$env:USERPROFILE\Documents\PowerShell\themes"
$themeFile  = "$themesDir\gruvbox.omp.json"

New-Item -ItemType Directory -Force $themesDir | Out-Null

if (Test-Path $themeFile) {
    Write-Skip "gruvbox theme"
} else {
    $url = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/gruvbox.omp.json"
    Invoke-WebRequest -Uri $url -OutFile $themeFile -UseBasicParsing
    Write-OK "gruvbox theme downloaded to $themeFile"
}

# ---------------------------------------------------------------------------
# 6. PowerShell profile
# ---------------------------------------------------------------------------
Write-Step "Writing PowerShell profile"

$profileContent = @'
oh-my-posh init pwsh --config "$env:USERPROFILE\Documents\PowerShell\themes\gruvbox.omp.json" | Invoke-Expression

Import-Module -Name Terminal-Icons

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function Complete
'@

New-Item -ItemType Directory -Force (Split-Path $PROFILE) | Out-Null

if (Test-Path $PROFILE) {
    $current = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($current -match "oh-my-posh") {
        Write-Skip "Profile (oh-my-posh already configured)"
    } else {
        # Append to an existing profile that has other customisations
        Add-Content $PROFILE "`n$profileContent"
        Write-OK "Appended oh-my-posh config to existing profile"
    }
} else {
    Set-Content $PROFILE $profileContent -Encoding UTF8
    Write-OK "Profile created at $PROFILE"
}

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Host @"

===============================================
  Setup complete!
===============================================
  One manual step in Windows Terminal:
    Settings -> PowerShell -> Appearance
    Font face: CaskaydiaCove NF

  Then open a new PowerShell tab to see
  the gruvbox prompt.
===============================================
"@ -ForegroundColor Green
