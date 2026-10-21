Write-Host "Checking requirements (Powershell 7, git & scoop)"

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Write-Host "    [OK] PowerShell $($PSVersionTable.PSVersion)"
} else {
    Write-Host "    [ERROR] PowerShell 7 or newer is required. Aborting..."
    exit
}

# Check Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "    [OK] Git is installed"
} else {
    Write-Host "[ERROR] Git is not installed. Aborting..."
    exit
}

# Check Scoop
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "    [OK] Scoop is installed"
} else {
    Write-Host "    [ERROR] Scoop is not installed. Aborting..."
    exit
}

# Install Oh My Posh

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Oh My Posh is installed"
} else {
    Write-Host "[*] Installing Oh My Posh"
    winget install JanDeDobbeleer.OhMyPosh --source winget
}

# Install Meslo Font
$installed_fonts = oh-my-posh font list

if ($installed_fonts.Contains("Meslo")) {
    Write-Host "[OK] Meslo Font is installed"
} else {
    Write-Host "[*] Installing Meslo Font"
    oh-my-posh font install meslo
}

# Trying to find the installed Microsoft Terminal in order to automatically configure the Powershell 7 profile and setting it as default.

$package = Get-AppxPackage |
    Where-Object { $_.Name -like "Microsoft.WindowsTerminal*" } |
    Select-Object -First 1

if ($package) {
    $settingsPath = Join-Path $env:LOCALAPPDATA `
        "Packages\$($package.PackageFamilyName)\LocalState\settings.json"
} else {
    $settingsPath = Join-Path $env:LOCALAPPDATA `
        "Microsoft\Windows Terminal\settings.json"
}

if (-not (Test-Path $settingsPath)) {
    throw "Windows Terminal settings.json not found."
}

Write-Host "Found settings for Microsoft Terminal: $settingsPath"

Write-Host "Backing up the original Settings File..."

Copy-Item $settingsPath "$settingsPath.bak" -Force

$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# Handle both modern ($settings.profiles.list) and legacy ($settings.profiles) schemas
$profilesList = if ($settings.profiles.list) { $settings.profiles.list } else { $settings.profiles }

# Match either "PowerShell" (PS 7+) or "Windows PowerShell" (PS 5.1)
$ps_profile = $profilesList | 
    Where-Object { $_.name -eq 'PowerShell' } | 
    Select-Object -First 1

if (-not $ps_profile) {
    throw "PowerShell profile not found in settings.json"
}

# Safely add or update the font configuration without wiping out existing font settings (like size)
if ($null -eq $ps_profile.font) {
    $fontObj = [PSCustomObject]@{ face = "MesloLGL Nerd Font" }
    $ps_profile | Add-Member -NotePropertyName 'font' -NotePropertyValue $fontObj -Force
} else {
    $ps_profile.font | Add-Member -NotePropertyName 'face' -NotePropertyValue "MesloLGL Nerd Font" -Force
}

# Safely set defaultProfile
$settings.defaultProfile = "$($ps_profile.guid)"

# Persist to disk
$settings |
    ConvertTo-Json -Depth 100 |
    Set-Content -Path $settingsPath -Encoding utf8

Write-Host "Successfully configured the Windows Terminal font."

Write-Host "Installing fzf and neovim"

# Install fzf
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Write-Host "    [OK] fzf is installed"
} else {
    Write-Host "    [*] Installing fzf"
    scoop install fzf
}

# Install neovim
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Write-Host "    [OK] neovim is installed"
} else {
    Write-Host "    [*] Installing neovim"
    scoop install neovim
}

# Install Modules
Write-Host "Installing modules posh-git, Termincal-Icon & PSFzf"

if (-not (Get-Module -ListAvailable -Name posh-git)) {
    Write-Host "    [*] Installing posh-git"
    Install-Module posh-git -Scope CurrentUser -Force
} else {
    Write-Host "    [OK] posh-git is already installed"
}

if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Write-Host "    [*] Installing Terminal-Icons"
    Install-Module Terminal-Icons -Scope CurrentUser -Force
} else {
    Write-Host "    [OK] Terminal-Icons is already installed"
}

if (-not (Get-Module -ListAvailable -Name PSFzf)) {
    Write-Host "    [*] Installing PSFzf"
    Install-Module PSFzf -Scope CurrentUser -Force
} else {
    Write-Host "    [OK] PSFzf is already installed"
}

Write-Host "Check if default Powershell Profile exists"

if (Test-Path $PROFILE) {
    Write-Host "    [OK] Powershell Profile already exists"
} else {
    Write-Host "    [*] Powershell Profile does not exist. Creating..."
    Write-Host "    "
    New-Item -Path $PROFILE -Type File -Force
}

Add-Content -Path $PROFILE -Value '. "$HOME\.config\powershell\user_profile.ps1"'

Write-Host "Check if Powershell User Profile exists"

if (Test-Path $HOME\.config\powershell\user_profile.ps1) {
    $confirmation = Read-Host "    [WARN] Powershell User Profile already exists. Do you want to overwrite it? (y/n)"

    if ($confirmation -eq "y") {
        Write-Host "    Continuing..."
        Remove-Item $HOME\.config\powershell\user_profile.ps1
    } else {
        Write-Host "    Operation cancelled."
        exit
    }
} else {
    Write-Host "    [*] Powershell User Profile does not exist. Downloading..."
}

curl.exe -L -s -o "$HOME\.config\powershell\user_profile.ps1" "https://raw.githubusercontent.com/0RB1T4L-dev/setup-scripts/refs/heads/main/windows/user_profile.ps1"

Write-Host "Setting up Themes Directory in User Home Directory"
New-Item -ItemType Directory -Path "$HOME\.config\posh\themes" -Force | Out-Null

Write-Host "Downloading powerlevel10k_rainbow.omp.json"
Remove-Item $HOME\.config\posh\themes\powerlevel10k_rainbow.omp.json
curl.exe -L -s -o "$HOME\.config\posh\themes\powerlevel10k_rainbow.omp.json" "https://raw.githubusercontent.com/0RB1T4L-dev/setup-scripts/refs/heads/main/windows/powerlevel10k_rainbow.omp.json"