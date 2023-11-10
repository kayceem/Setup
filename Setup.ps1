try {   
    if (!(Test-Path -Path ($ENV:USERPROFILE + "\Documents\Powershell"))) {
        New-Item -Path ($ENV:USERPROFILE + "\Documents\Powershell") -ItemType Directory
    }
    Invoke-RestMethod https://github.com/kayceem/setup/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
    Write-Host "The profile @ [$PROFILE] has been created."
}
catch {
    throw $_.Exception.Message
}

winget install -e --accept-source-agreements --accept-package-agreements Starship.Starship

# Font Install
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families

# Check if CaskaydiaCove NF is installed
if ($fontFamilies -notcontains "CaskaydiaCove NF") {

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile("https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip", ".\CascadiaCode.zip")
    Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode" -Force
    $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
    Get-ChildItem -Path ".\CascadiaCode" -Recurse -Filter "*.ttf" | ForEach-Object {
        If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {        
            # Install font
            $destination.CopyHere($_.FullName, 0x10)
        }
    }

    # Clean up
    Remove-Item -Path ".\CascadiaCode" -Recurse -Force
    Remove-Item -Path ".\CascadiaCode.zip" -Force
}

$modulesName = @("Terminal-Icons", "z")
foreach ($moduleName in $modulesName) {
    $module = Get-Module -ListAvailable | Where-Object { $_.Name -eq $moduleName }
    if (-not $module) {
        Write-Output "Module $moduleName is not installed. Installing..."
        Install-Module -Name $moduleName -Repository PSGallery -Force
    }
    else {
        Write-Output "Module $moduleName is already installed."
    }
}