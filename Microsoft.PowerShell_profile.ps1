##########################################################
####################    Powershell    ####################
##########################################################

# Navigate forward and backward history
function n {
    cdX + -ErrorAction SilentlyContinue
}
function b {
    cdX - -ErrorAction SilentlyContinue
}

# Clear History from powershell
function Clear-History {
    try {
        $historyFile = (Get-PSReadlineOption).HistorySavePath
        if ([System.IO.File]::Exists($historyFile)) {
            [System.IO.File]::WriteAllText($historyFile, "")
        }
        else {
            Write-Host "No history to clear."
        }
    }
    catch {
        Write-Host "An error occurred while attempting to clear the history: $_"
    }
}

# Grep
function grep {
    param(
        $regex
    )
    $input | select-string $regex
}

# Exit powershell
function Exit-Powershell {
    exit
}
Set-Alias -Name \q -Value Exit-Powershell

# Create an empty file
function touch($file) {
    "" | Out-File $file -Encoding ASCII
}
Set-Alias -Name new -Value touch

# Set env variable (temporary)
function export {
    param(
        $name,
        $value
    )
    Set-Item -force -path "env:$name" -value $value;
}

# Refresh powershell profile
function Refresh-Powershell {
    & $PROFILE
}
Set-Alias -Name refresh -Value Refresh-Powershell

# Reload powershell
function Reload-Powershell {
    # Invoke-Command { & "pwsh.exe" } -NoNewScope 
    Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope }
}
Set-Alias -Name reload -Value Reload-Powershell

# Set env variable (presistent)
function Set-Enviroment-Variable {
    param(
        $name,
        $value
    )
    [Environment]::SetEnvironmentVariable($name, $value, "User")
}

# Delete items to recycle bin
function Remove-ItemRecycleBin {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'Directory path of file path for deletion.')]
        [String]$LiteralPath,
        [Parameter(Mandatory = $false, HelpMessage = 'Allows user to delete non empty directories.')]
        [Switch]$Force
    )
  
    Add-Type -AssemblyName Microsoft.VisualBasic
    $item = Get-Item -LiteralPath $LiteralPath -ErrorAction SilentlyContinue
  
    if ($null -eq $item) {
        Write-Error("'{0}' not found" -f $LiteralPath)
    }
    else {
        $fullpath = $item.FullName
        
        if (Test-Path -LiteralPath $fullpath -PathType Container) {
            $HasChildren = (Get-ChildItem -Path $fullpath -Force).Count -gt 0
            if ($Force -or !$HasChildren) {
                Write-Verbose ("Moving '{0}' folder to the Recycle Bin" -f $fullpath)
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($fullpath, 'OnlyErrorDialogs', 'SendToRecycleBin')
            }
            else {
                Write-Error("Use -Force to delete a folder with content")
            }
        }
        else {
            Write-Verbose ("Moving '{0}' file to the Recycle Bin" -f $fullpath)
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($fullpath, 'OnlyErrorDialogs', 'SendToRecycleBin')
        }
    }
}
Set-Alias -Name trash -Value Remove-ItemRecycleBin
Set-Alias -Name rb -Value Remove-ItemRecycleBin

# Search for a file
function Find-File {
    param(
        $name
    )
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        # $place_path = $_.directory
        # Write-Output "${place_path}"
        Write-Output "${_}"
    }
}
Set-Alias -Name find -Value Find-File

# List files only
function List-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$path = ".",
        [switch]$Name
    )

    if (-not (Test-Path -Path $path)) {
        Write-Error "Invalid path: $path"
        return
    }

    $files = Get-ChildItem -File -Force -Path $path

    if ($Name) {
        $files | Select-Object -ExpandProperty Name
    }
    else {
        $files
    }
}
Set-Alias -Name ll -Value List-File

# List folders only
function List-Folder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$path = ".",
        [switch]$Name
    )
    if (-not (Test-Path -Path $path)) {
        Write-Error "Invalid path: $path"
        return
    }
    $folders = Get-ChildItem -Directory -Force -Path $path
    if ($Name) {
        $folders | Select-Object -ExpandProperty Name
    }
    else {
        $folders
    }
}
Set-Alias -Name ld -Value List-Folder 

##########################################################
##################    Backup/Restore    ##################
##########################################################

# Go to backup
function Navigate-Backup {
    Set-Location $ENV:Backup
}
Set-Alias -Name nb -Value Navigate-Backup

# Backup all
function Backup-All {
    Backup-Profile
    Backup-Starship
    Backup-Git
    Write-Host "Backed up: Git | Profile | Starship"
}
Set-Alias -Name ba -Value Backup-All

# Create Powershell backup
function Backup-Git {
    $Source = Join-Path $HOME ".gitconfig"
    $Destinaton = Join-Path $ENV:Backup "Git"
    Copy-Item -Path $Source `
        -Destination $Destinaton `
        -Recurse `
        -Force
}

# Create Powershell backup
function Backup-Profile {
    $Source = Join-Path $ENV:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    $Destinaton1 = Join-Path $ENV:Backup "Powershell"
    $Destinaton2 = Join-Path $HOME "Documents\Setup"
    # Profile
    Copy-Item -Path $PROFILE `
        -Destination $Destinaton1 `
        -Recurse `
        -Force
    # Settings
    Copy-Item -Path $Source `
        -Destination $Destinaton1 `
        -Recurse `
        -Force
    # Profile to setup
    Copy-Item -Path $PROFILE `
        -Destination $Destinaton2 `
        -Recurse `
        -Force
}
Set-Alias -Name backup -Value Backup-Profile

# Create Starship backup
function Backup-Starship {
    $Source = Join-Path $HOME ".config\starship.toml"
    $Destination = Join-Path $ENV:Backup "Starship\.config\"
    Copy-Item -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force
}

# Create VsCode backup
function Backup-VsCode {
    $Source = Join-Path $ENV:APPDATA "Code\User"
    $Destination = Join-Path $ENV:Backup "Vscode"
    Copy-Item -Path (Join-Path $Source "*.json") `
        -Destination $Destination `
        -Recurse `
        -Force
    Copy-Item -Path (Join-Path $Source "snippets") `
        -Destination $Destination `
        -Recurse `
        -Force
}

# Create Taskschedule backup
function Export-Tasks() {
    $Destination = Join-Path $ENV:BACKUP "Tasks"
    if (!(Test-Path $Destination)) {
        New-Item -ItemType Directory -Force -Path $Destination
    }
    $tasks = Get-ScheduledTask | Where-Object { $_.TaskPath -eq '\Custom\' }
    foreach ($task in $tasks) {
        $taskPath = Join-Path $Destination ($task.TaskName + ".xml")
        $task | Export-Clixml $taskPath
    }
}

# Restore All
function Restore-All() {
    Import-Tasks
    Import-AHK
    Import-Rainmeter
    Restore-Powershell
    Restore-Starship
}

# Restore AHK
function Import-AHK() {
    $Source = Join-Path $ENV:BACKUP "AHK"
    $Destination = Join-Path $HOME "Documents"
    Copy-Item -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force
}

# Restore AHK
function Import-Rainmeter() {
    $Source = Join-Path $ENV:BACKUP "Rainmeter"
    $Destination = Join-Path $HOME "Documents"
    Copy-Item -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force
}

# Restore Tasks
function Import-Tasks() {
    $Source = Join-Path $ENV:BACKUP "Tasks"
    $files = Get-ChildItem $Source -Filter "*.xml"
    foreach ($file in $files) {
        $task = Import-Clixml $file.FullName
        $task | Register-ScheduledTask
        Write-Host "Imported task from $($file.FullName)"
    }
}

# Restore Powershell settings
function Restore-Powershell {
    $Source = Join-Path $ENV:Backup "Powershell\settings.json"
    $Destination = Join-Path $ENV:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    Copy-Item -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force
}

# Restore Starship
function Restore-Starship {
    $Source = Join-Path $ENV:Backup "Starship\.config\starship.toml"
    $Destination = Join-Path $HOME ".config\"
    if (-not(Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination
    }
    Copy-Item -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force
}

# Restore VsCode
function Restore-VsCode {
    $Source = Join-Path $ENV:Backup "Vscode"
    $Destination = Join-Path $ENV:APPDATA "Code\User"
    if (-not(Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination
    }
    Copy-Item -Path (Join-Path $Source "*.json") `
        -Destination $Destination `
        -Recurse `
        -Force
    Copy-Item -Path (Join-Path $Source "snippets") `
        -Destination $Destination `
        -Recurse `
        -Force
}

# Restore VLC
function Restore-VLC-Player {
    $Source = Join-Path $ENV:BACKUP "vlc"
    $Destination = Join-Path $ENV:APPDATA "vlc"
    if (-not(Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination
    }
    Copy-Item -Path $Source\* `
        -Destination $Destination\ `
        -Recurse `
        -Force
}
Set-Alias -Name vlcr -Value Restore-VLC-Player

##########################################################
####################    Start/Stop    ####################
##########################################################

# Stop Nord
function Stop-Nord-VPN {
    try {
        taskkill /f /im "NordVPN.exe"
        net stop NordUpdaterService
        net stop nordvpn-service
        Write-Host "Nord VPN stopped."
    }
    catch {
        Write-Host "Could not stop nord vpn."
    }
}
Set-Alias -Name nordp -Value Stop-Nord-VPN

# Start Nord
function Start-Nord-VPN {
    try {
        net start nordvpn-service
        Start-Process "C:\Program Files\NordVPN\NordVPN.exe"
        Write-Host "Nord VPN running..."
    }
    catch {
        Write-Host "Could not start nord vpn."
    }
}
Set-Alias -Name nords -Value Start-Nord-VPN

# Start Docker
function Start-Docker-Desktop {
    try {
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        Write-Host "Docker desktop running..."
    }
    catch {
        Write-Host "Could not start docker desktop."
    }
}
Set-Alias -Name dockers -Value Start-Docker-Desktop

# Stop Docker
function Stop-Docker {
    try {
        taskkill /f /im "docker desktop.exe"
        taskkill /f /im "docker.exe"
        taskkill /f /im "com.docker*"
        wsl --shutdown
    }
    catch {
        Write-Host "Could not stop docker."
    }
}
Set-Alias -Name dockerp -Value Stop-Docker

# Get processes
function Get-Processes {
    param(
        $name
    )
    if ($null -eq $name) {
        Write-Host "No processes found."
        return
    }
    $processes = Get-Process -ErrorAction SilentlyContinue
    $found = $false
    foreach ($process in $processes) {
        try {
            if ($process.Mainmodule.FileVersionInfo.FileDescription -match $name) {
                $process
                $found = $true
            }
        }
        catch {
            continue
        }
    }

    if (-not $found) {
        Write-Host "No processes found with the given description."
    }
}
Set-Alias -Name pgrep -Value Get-Processes

# Kill processes
function Stop-Processes {
    param(
        $name
    )
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}
Set-Alias -Name pkill -Value Stop-Processes

##########################################################
######################    Extras    ######################
##########################################################

# Light Mode
function Light-Mode {
    Start-ScheduledTask -TaskName "\Custom\Light Mode"
}
Set-Alias -Name light -Value Light-Mode 

# Dark Mode
function Dark-Mode {
    Start-ScheduledTask -TaskName "\Custom\Dark Mode"
}
Set-Alias -Name dark -Value Dark-Mode 

# Activate Virtual Environment
function Activate-Environment {
    try {
        .\.venv\Scripts\activate
    }
    catch {
        Write-Host "No .venv environments!"
    }
}
Set-Alias -Name activate -Value Activate-Environment 

# Open Messenger
function Messenger {
    Start-Process "https://messenger.com"
    Write-Host "Opening Messenger..."
}
Set-Alias -Name ms -Value Messenger

# Shutdown
function Power-Off {
    param(
        $minutes
    )
    if ($null -eq ($minutes -as [int])) {
        $cancel = $minutes
        if ($cancel -eq "off" -or $cancel -eq "Off" -or $cancel -eq "a") {
            shutdown /a
            Write-Host "Shudwon canceled."
            return
        }
        if ($cancel -eq "now" -or $cancel -eq "Now") {
            shutdown /s /t 0
            return
        }
        Write-Host "Invalid argument!" -f Red
        return
    }
    if (!$minutes -or $minutes -lt 1) {
        Write-Host "Please enter time in minutes..."
        return
    }
    $minutes = $minutes * 60
    shutdown /s /t $minutes
    Write-Host "Logging off in $minutes seconds..."

}
Set-Alias -Name off -Value Power-Off

# Start youtube
function Youtube {
    Start-Process "https://youtube.com"
    Write-Host "Opening Youtube..."
}
Set-Alias -Name yt -Value Youtube

# Open github
function Github {
    Start-Process "https://github.com"
    Write-Host "Opening Github..."
}
Set-Alias -Name gh -Value Github

# Search Web
function Search-Web {
    $query = $args -join " "
    if (!$query) {
        Write-Host "Enter keyword to search!"
        return
    }
    # Write-Host @args
    Start-Process "https://www.google.com/search?q=$query"
}
Set-Alias -Name search -Value Search-Web

# Alias for virtualen
Set-Alias -Name venv -Value virtualenv

# Alias for neovim
Set-Alias -Name vim -Value nvim

# Open Notepad
Set-Alias -Name np -Value notepad

# Open Explorer
Set-Alias -Name ex -Value explorer

##########################################################
######################    Github    ######################
##########################################################
# Createa github repo
function Create-Repo {
    param (
        [string]$repoName,
        [string]$val
    )

    # Check if the repository name is provided
    if ($repoName -eq $null -or $repoName -eq "") {
        Write-Error "Repository name must be provided"
        return
    }

    # Set your GitHub credentials
    $token = $Env:GITHUB

    # Set the repository name and description
    $repoDescription = ""

    # Create the repository
    $body = @{
        name        = $repoName
        description = $repoDescription
        private     = If ($val.ToLower() -eq "false" -or $val.ToLower() -eq "f") { $false } Else { $true }
    } | ConvertTo-Json
    $headers = @{
        "Authorization" = "Token $token"
    }
    $response = Invoke-WebRequest -Method Post -Uri "https://api.github.com/user/repos" -Body $body -ContentType "application/json" -Headers $headers
    if ($response.StatusCode -eq 201) {
        Write-Host "The repository $repoName has been created successfully"
    }
    else {
        Write-Host "An error occurred while creating the repository $repoName"
    }
}
Set-Alias -Name createrepo -Value Create-Repo

# Delete a github repo
function Delete-Repo {
    param (
        [string]$repoName
    )

    # Set your GitHub credentials
    $username = "kayceem"
    $token = $Env:GITHUB

    # Check if the repository name is provided
    if ($repoName -eq $null -or $repoName -eq "") {
        Write-Error "Repository name must be provided"
        return
    }

    # Prompt user for confirmation
    $confirmation = Read-Host "Are you sure you want to delete the repository $repoName? (Yes/N)"
    if ($confirmation -eq "Yes" -or $confirmation -eq "yes" -or $confirmation -eq "YES") {
        # Delete the repository
        $headers = @{
            "Authorization" = "Token $token"
        }
        $git_error = $null
        try {
            $response = Invoke-WebRequest -Method Delete -Uri "https://api.github.com/repos/$username/$repoName" -Headers $headers -ErrorVariable $git_error
        }
        catch {
            
        }
        if (!$git_error) {
            if ($response.StatusCode -eq 204) {
                Write-Host "The repository $repoName has been deleted successfully"
            }
            elseif ($response.StatusCode -eq 404) {
                Write-Error "The repository $repoName does not exist"
            }
            else {
                Write-Host "An error occurred while deleting the repository $repoName"
            }
        }
        else {
            Write-Host "An error occurred while deleting the repository $repoName"
        }
    }
    else {
        Write-Host "Repository deletion cancelled."
    }
}
Set-Alias -Name deleterepo -Value Delete-Repo

# Get repo github
function Get-Repos {
    # Set your GitHub credentials
    $token = $Env:GITHUB

    # Get the list of repositories
    $headers = @{
        "Authorization" = "Token $token"
    }
    $response = Invoke-WebRequest -Method Get -Uri "https://api.github.com/user/repos?per_page=100" -Headers $headers
    $repos = $response.Content | ConvertFrom-Json

    # Display the repository names
    Write-Host ""
    $i = 1
    $repos | ForEach-Object {
        Write-Host "$i." $_.name
        Write-Host "                        Private: " $_.private
        $i++
    }
}
Set-Alias -Name getrepo -Value Get-Repos

# Create gist github
function Create-Gist {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (-not (Test-Path $FilePath -PathType Leaf)) {
        Write-Host "File not found."
        return
    }
    $DestinationPath = Join-Path "E:\Gists" $Description


    $Content = Get-Content $FilePath -Raw
    $FileName = Split-Path $FilePath -Leaf

    $Uri = "https://api.github.com/gists"
    $Headers = @{
        "Accept"               = "application/vnd.github+json"
        "Authorization"        = "Bearer $ENV:Gists"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    $Body = @{
        description = $Description
        public      = $true
        files       = @{
            $FileName = @{
                content = $Content
            }
        }
    } | ConvertTo-Json
    $GitError = $null
    try {
        $Response = Invoke-WebRequest -Method Post -Uri $Uri -Headers $Headers -Body $Body -ErrorVariable $GitError
    }
    catch {
        Write-Host $GitError
    }
    if (-not ($Response.StatusCode -eq 201)) {
        Write-Host "An error occurred while creating the gist $FileName"
        return
    } 
    Write-Host "The gist $FileName has been created successfully"
    try {
        $GitPullUrl = (ConvertFrom-Json $Response).git_pull_url
        git clone $GitPullUrl $DestinationPath
        Write-Host "The gist $FileName has been cloned."
    }
    catch {
        Write-Host "An error occurred: $_"
    }

}
Set-Alias -Name gistc -Value Create-Gist

##########################################################
#####################    On Start    #####################

#####################    StarShip    #####################
# Set config location
$ENV:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
# Start Starship
Invoke-Expression (&starship init powershell)

#######################    Setup    ######################
Set-PSReadLineOption -PredictionViewStyle ListView
Clear-History

######################    Imports    #####################
# Import-Module Terminal-Icons
