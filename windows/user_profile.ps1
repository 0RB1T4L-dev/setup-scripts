# Prompt
Import-Module posh-git
oh-my-posh init pwsh --config "$HOME\.config\posh\themes\powerlevel10k_rainbow.omp.json" | Invoke-Expression

# Terminal Icons
Import-Module -Name Terminal-Icons

# PSReadLine configuration
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# PSFzf fuzzy finder
Import-Module PSFzf
Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'

# Aliases
Set-Alias vim nvim
Set-Alias grep findstr

# Utilities
function which($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function cptxt($path) {
    Get-Content $path | clip
}