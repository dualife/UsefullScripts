# script de personnalisation de W11

# main function
function Do_CFConfigureW11{
	# Write-CFConsoleLog "sortie $($?)"
	Write-CFConsoleLog "$((Get-Date -format ""yyyy-MM-dd_HH-mm-ss"")) - Début script de personnalisation de W11"
	
	Write-CFConsoleLog "Applique le thème sombre"
	Set-CFDefaultAndUsersRegKey -keyPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -entryName "AppsUseLightTheme" -entryPropertyType DWord -entryValue 0
	
	Write-CFConsoleLog "Met le clavier francais sur langue US pour le user courant uniquement"
	Set-WinDefaultInputMethodOverride -InputTip "0409:0000040C"
	
	Write-CFConsoleLog "Barre des taches alignée a gauche"
	Set-CFDefaultAndUsersRegKey -keyPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -entryName "TaskbarAl" -entryPropertyType DWord -entryValue 0
	
	Write-CFConsoleLog "Barre des taches: désactive bouton view"
	Set-CFDefaultAndUsersRegKey -keyPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -entryName "ShowTaskViewButton" -entryPropertyType DWord -entryValue 0
	
	Write-CFConsoleLog "Applique config explorer affiche fichers cachés"
	Set-CFDefaultAndUsersRegKey -keyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -entryName "Hidden" -entryPropertyType DWord -entryValue 1
	
	Write-CFConsoleLog "Applique config explorer affiche extension fichers"
	Set-CFDefaultAndUsersRegKey -keyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -entryName "HideFileExt" -entryPropertyType DWord -entryValue 0
	
	Write-CFConsoleLog "Applique config explorer affiche fichers super cachés"
	Set-CFDefaultAndUsersRegKey -keyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -entryName "ShowSuperHidden" -entryPropertyType DWord -entryValue 1
	
	Write-CFConsoleLog "Applique config explorer demarre sur PC"
	Set-CFDefaultAndUsersRegKey -keyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -entryName "LaunchTo" -entryPropertyType DWord -entryValue 1
	
	Write-CFConsoleLog "application configuration explorer full menu"
	Set-CFDefaultAndUsersRegKey -keyPath "Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -entryName "(default)" -entryPropertyType String -entryValue ""
	
	Write-CFConsoleLog "Barre des taches: désactive bouton search"
	Set-CFDefaultAndUsersRegKey -keyPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -entryName "SearchboxTaskbarMode" -entryPropertyType DWord -entryValue 0
	
	Write-CFConsoleLog "Barre des taches: désactive bouton chat"
	New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" -force
	New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" -name "ChatIcon" -value 3 -force
	
	Write-CFConsoleLog "Barre des taches: ajoute le clavier virtuel"
	Set-CFDefaultAndUsersRegKey -keyPath "SOFTWARE\Microsoft\TabletTip\1.7" -entryName "TipbandDesiredVisibility" -entryPropertyType DWord -entryValue 1
	
	Write-CFConsoleLog "Configuration autoUpdate microsoft products sur windows update"
	$ServiceManager = (New-Object -com "Microsoft.Update.ServiceManager")
	$ServiceManager.Services
	$ServiceID = "7971f918-a847-4430-9279-4a52d1efe18d"
	$ServiceManager.AddService2($ServiceId,7,"")
	
	Write-CFConsoleLog "Configuration windows update notifier quand reboot requis"
	New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings\" -name "RestartNotificationsAllowed2" -value 1 -force
	
	Install_CFWingetPrograms
	
	Write-CFConsoleLog "application config windows terminal"
	$pwshSettingPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
	$pwshSettingBackupPath = "$pwshSettingPath\$((Get-Date -format ""yyyy-MM-dd_HH-mm-ss""))_settings.json"
	
	Write-CFConsoleLog "backup du config actuel dans"
	Write-CFConsoleLog $pwshSettingBackupPath
	Copy-Item "$pwshSettingPath\settings.json" -Destination $pwshSettingBackupPath
	
	if ($? -eq $true) {
		Write-CFConsoleLog "backup réussi, application de la config"
		Set-Content -Path "$pwshSettingPath\settings.json" -Value $pwshSetting
		
		if ($? -eq $false) {
			Write-CFConsoleLog "echec d'application du setting windowns terminal, abort" -kind "error"
		} else {
			Write-CFConsoleLog "application réussie"
		}
	} else {
		Write-CFConsoleLog "echec du backup, abort" -kind "error"
	}
	
	Write-CFConsoleLog "Redémarre l'explorer pour prendre en compte les nouveaux paramètres"
	stop-process -name explorer –force
	
	Write-CFConsoleLog "$((Get-Date -format ""yyyy-MM-dd_HH-mm-ss"")) - Fin script de personnalisation de W11"
	
	Write-CFConsoleLog "Fin du script"
	Restart_CFComputerWithPrompt
}

# custom functions
# prefixer les fonctions par CF (custom Function)

function Install_CFWingetPrograms{
	
	## The following four lines only need to be declared once in your script.
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Lance les installs."
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Skippe les installs."
	# $cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel","Description."
	# $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $cancel)
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	
	## Use the following each time your want to prompt the use
	$title = "Lancer les installs Winget?"
	$message = "Lancer les installs Winget?"
	$result = $host.ui.PromptForChoice($title, $message, $options, 1)
	switch ($result) {
	  0{
		Write-CFConsoleLog "Installs"
		
		Write-CFConsoleLog "Mise a jour des références winget"
		winget source update
		if ($? -ne $true) {
			Write-CFConsoleLog "Erreur lors de Mise a jour des références winget: sortie $($?)" -kind "error"
		}
		
		Write-CFConsoleLog "Désinstallation de skype"
		winget uninstall skype --purge --accept-source-agreements
		if ($? -ne $true) {
			Write-CFConsoleLog "Erreur lors de désinstallation winget: sortie: $($?)" -kind "error"
		} else {
			Write-CFConsoleLog "désinstallation de $($id) réussie"
		}
		
		Write-CFConsoleLog "Désinstallation des widgets"
		Uninstall_CFWingetApp 9MSSGKG348SP
		
		Write-CFConsoleLog "Désinstallation de Microsoft Teams"
		Uninstall_CFWingetApp MicrosoftTeams_8wekyb3d8bbwe
		
		Write-CFConsoleLog "Installation de Chrome"
		Install_CFWingetApp Google.Chrome
		
		Write-CFConsoleLog "Installation de Mozilla.Firefox"
		Install_CFWingetApp Mozilla.Firefox
		
		Write-CFConsoleLog "Installation de TeamViewer"
		Install_CFWingetApp TeamViewer.TeamViewer
		
		Write-CFConsoleLog "Installation de Notepad++"
		Install_CFWingetApp Notepad++.Notepad++
		
		Write-CFConsoleLog "Installation de VideoLAN.VLC"
		Install_CFWingetApp VideoLAN.VLC
		
		Write-CFConsoleLog "Installation de Discord"
		Install_CFWingetApp Discord.Discord
		
		Write-CFConsoleLog "Installation de DominikReichl.KeePass"
		Install_CFWingetApp DominikReichl.KeePass
		
		Write-CFConsoleLog "Installation de WinMerge"
		Install_CFWingetApp WinMerge.WinMerge
		
		Write-CFConsoleLog "Installation de WinDirStat"
		Install_CFWingetApp WinDirStat.WinDirStat
		
		Write-CFConsoleLog "Installation de 7zip"
		Install_CFWingetApp 7zip.7zip
		
		Write-CFConsoleLog "Installation de WingetUIStore"
		Install_CFWingetApp SomePythonThings.WingetUIStore
		
		Write-CFConsoleLog "Installation de AgentRansack"
		Install_CFWingetApp Mythicsoft.AgentRansack
		
		Write-CFConsoleLog "Installation de PowerShell"
		Install_CFWingetApp Microsoft.PowerShell
		
		Write-CFConsoleLog "Installation de PowerToys"
		Install_CFWingetApp Microsoft.PowerToys
		
		Write-CFConsoleLog "Installation de Ventoy"
		winget install --id ventoy.Ventoy --exact --source winget --accept-source-agreements --force --location "C:\Program Files"
		# ensuite deplacer version 64bits qui est dans altexe dans dossier parents
		Move-Item -path "C:\Program Files\ventoy-1.0.88\altexe\Ventoy2Disk_X64.exe" -destination "C:\Program Files\ventoy-1.0.88\Ventoy2Disk_X64.exe"
		# puis reparer le symlink de winget path
		New-Item -Type SymbolicLink -Path "C:\Users\gosse\AppData\Local\Microsoft\WinGet\Links\ventoy.exe" -Target "C:\Program Files\ventoy-1.0.88\Ventoy2Disk_X64.exe" -Force
		
		Write-CFConsoleLog "Installation de Axosoft.GitKraken"
		Install_CFWingetApp Axosoft.GitKraken
		
	  }1{
		Write-CFConsoleLog "Skippé"
	  }
	}
}

function Install_CFWingetApp{
	param (
		[string]$id
	)
	
	winget list --id $id
	if($?) {
		Write-CFConsoleLog "$id est déjà installé, skipped."
	}
	else {
		Write-CFConsoleLog "($id): installation..."
		
		winget install --id $id --exact --source winget --accept-source-agreements --force --silent
		if ($? -ne $true) {
			Write-CFConsoleLog "Erreur lors de l'installation winget: sortie: $($?)" -kind "error"
		} else {
			Write-CFConsoleLog "installation de $($id) réussie"
		}
	}
}

function Uninstall_CFWingetApp{
	param (
		[string]$id
	)
	
	winget list --id $id
	if($?) {
		Write-CFConsoleLog "($id): desinstallation..."
		
		winget uninstall --id $id --purge --accept-source-agreements
		if ($? -ne $true) {
			Write-CFConsoleLog "Erreur lors de désinstallation winget: sortie: $($?)" -kind "error"
		} else {
			Write-CFConsoleLog "désinstallation de $($id) réussie"
		}
	} else {
		Write-CFConsoleLog "$id n'a pas été trouvé, desinstallation skippée."
	}
}

function Restart_CFComputerWithPrompt{
	
	## The following four lines only need to be declared once in your script.
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Lance le redémarrage immediatement."
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Arrete l'éxecution du script sans redémarrer."
	# $cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel","Description."
	# $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $cancel)
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

	## Use the following each time your want to prompt the use
	$title = "Redemarrage requis"
	$message = "Redémarrer maintenant?"
	$result = $host.ui.PromptForChoice($title, $message, $options, 1)
	switch ($result) {
	  0{
		Write-Host "Redémarrage"
		Restart-computer
	  }1{
		Write-Host "Fin"
	  }
	}
}

function Write-CFConsoleLog{
	param (
		[string]$text,
		[string]$kind = "info"
    )
	
	if ($kind -eq "info") {
		Write-Host $text -ForegroundColor DarkGreen
	} else {
		Write-Error $text
	}
}

function Set-CFAllUsersRegKey {

    param (
		[string]$keyPath,
		[string]$entryName,
		[string]$entryPropertyType,
		[object]$entryValue
    )
	
	# Get the list of user profiles from the HKEY_USERS registry hive excluding system users
	$profiles = Get-ChildItem "Registry::HKEY_USERS" | Where-Object { $_.PSChildName -like "S-1-5-21-*" -and $_.PSChildName -notlike "*_Classes"}

	# test if drive already mounted
	if (!(Test-Path "HKU:")) {
		# mount as ps drive USERS hive since not avalaible by defaut
		New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
	}

	# Loop through each user profile
	foreach ($profile in $profiles) {
		# build key path depending on user and path
		$regkey = "HKU:\$($profile.PSChildName)\$keyPath"
		# test if key exist
		# if (Test-Path $regkey) {
			# Write-Host "The registry key $regkey exists."
		# } else {
			# Write-Host "The registry key $regkey does not exist."
		# }
		
		# si path n'existe pas, le créé
		if (!(Test-Path regkey)) {
			New-Item -Path regkey
		}
		
		# apply to user
		New-ItemProperty -Path $regkey -Name $entryName -PropertyType $entryPropertyType -Value $entryValue -Force		
	}
}

function Set-CFDefaultAndUsersRegKey {

    param (
		[string]$keyPath,
		[string]$entryName,
		[string]$entryPropertyType,
		[object]$entryValue
    )
	
	# $HKCUPath = "HKCU:\$keyPath"
	# # si path pour le user n'existe pas, le créé
	# if (!(Test-Path $HKCUPath)) {
		# New-Item -Path $HKCUPath
	# }

	# # apply to current user config
	# New-ItemProperty -Path $HKCUPath -Name $entryName -PropertyType $entryPropertyType -Value $entryValue -Force
	
	# test if drive already mounted
	if (!(Test-Path "HKU:")) {
		# mount as ps drive USERS hive since not avalaible by defaut
		New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
	}

	$HKUPath = "HKU:\.DEFAULT\$keyPath"
	# si path pour le default user n'existe pas, le créé
	if (!(Test-Path $HKUPath)) {
		New-Item -Path $HKUPath
	}

	# apply to default config for future users
	New-ItemProperty -Path $HKUPath -Name $entryName -PropertyType $entryPropertyType -Value $entryValue -Force

	# Apply to all users already logged once
	Set-CFAllUsersRegKey $keyPath $entryName $entryPropertyType $entryValue
}

# ressources

$pwshSetting = [string] @'
{
    "$help": "https://aka.ms/terminal-documentation",
    "$schema": "https://aka.ms/terminal-profiles-schema",
    "actions": 
    [
        {
            "command": 
            {
                "action": "copy",
                "singleLine": false
            },
            "keys": "ctrl+c"
        },
        {
            "command": "paste",
            "keys": "ctrl+v"
        },
        {
            "command": "find",
            "keys": "ctrl+shift+f"
        },
        {
            "command": 
            {
                "action": "splitPane",
                "split": "auto",
                "splitMode": "duplicate"
            },
            "keys": "alt+shift+d"
        }
    ],
    "copyFormatting": "none",
    "copyOnSelect": false,
    "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
    "profiles": 
    {
        "defaults": 
        {
            "elevate": true
        },
        "list": 
        [
            {
                "commandline": "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
                "elevate": true,
                "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
                "hidden": false,
                "name": "Windows PowerShell"
            },
            {
                "commandline": "%SystemRoot%\\System32\\cmd.exe",
                "elevate": true,
                "guid": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}",
                "hidden": false,
                "name": "Command Prompt"
            },
            {
                "guid": "{b453ae62-4e3d-5e58-b989-0a998ec441b8}",
                "hidden": false,
                "name": "Azure Cloud Shell",
                "source": "Windows.Terminal.Azure"
            },
            {
                "elevate": true,
                "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
                "hidden": false,
                "name": "PowerShell",
                "source": "Windows.Terminal.PowershellCore"
            }
        ]
    },
    "schemes": 
    [
        {
            "background": "#0C0C0C",
            "black": "#0C0C0C",
            "blue": "#0037DA",
            "brightBlack": "#767676",
            "brightBlue": "#3B78FF",
            "brightCyan": "#61D6D6",
            "brightGreen": "#16C60C",
            "brightPurple": "#B4009E",
            "brightRed": "#E74856",
            "brightWhite": "#F2F2F2",
            "brightYellow": "#F9F1A5",
            "cursorColor": "#FFFFFF",
            "cyan": "#3A96DD",
            "foreground": "#CCCCCC",
            "green": "#13A10E",
            "name": "Campbell",
            "purple": "#881798",
            "red": "#C50F1F",
            "selectionBackground": "#FFFFFF",
            "white": "#CCCCCC",
            "yellow": "#C19C00"
        },
        {
            "background": "#012456",
            "black": "#0C0C0C",
            "blue": "#0037DA",
            "brightBlack": "#767676",
            "brightBlue": "#3B78FF",
            "brightCyan": "#61D6D6",
            "brightGreen": "#16C60C",
            "brightPurple": "#B4009E",
            "brightRed": "#E74856",
            "brightWhite": "#F2F2F2",
            "brightYellow": "#F9F1A5",
            "cursorColor": "#FFFFFF",
            "cyan": "#3A96DD",
            "foreground": "#CCCCCC",
            "green": "#13A10E",
            "name": "Campbell Powershell",
            "purple": "#881798",
            "red": "#C50F1F",
            "selectionBackground": "#FFFFFF",
            "white": "#CCCCCC",
            "yellow": "#C19C00"
        },
        {
            "background": "#282C34",
            "black": "#282C34",
            "blue": "#61AFEF",
            "brightBlack": "#5A6374",
            "brightBlue": "#61AFEF",
            "brightCyan": "#56B6C2",
            "brightGreen": "#98C379",
            "brightPurple": "#C678DD",
            "brightRed": "#E06C75",
            "brightWhite": "#DCDFE4",
            "brightYellow": "#E5C07B",
            "cursorColor": "#FFFFFF",
            "cyan": "#56B6C2",
            "foreground": "#DCDFE4",
            "green": "#98C379",
            "name": "One Half Dark",
            "purple": "#C678DD",
            "red": "#E06C75",
            "selectionBackground": "#FFFFFF",
            "white": "#DCDFE4",
            "yellow": "#E5C07B"
        },
        {
            "background": "#FAFAFA",
            "black": "#383A42",
            "blue": "#0184BC",
            "brightBlack": "#4F525D",
            "brightBlue": "#61AFEF",
            "brightCyan": "#56B5C1",
            "brightGreen": "#98C379",
            "brightPurple": "#C577DD",
            "brightRed": "#DF6C75",
            "brightWhite": "#FFFFFF",
            "brightYellow": "#E4C07A",
            "cursorColor": "#4F525D",
            "cyan": "#0997B3",
            "foreground": "#383A42",
            "green": "#50A14F",
            "name": "One Half Light",
            "purple": "#A626A4",
            "red": "#E45649",
            "selectionBackground": "#FFFFFF",
            "white": "#FAFAFA",
            "yellow": "#C18301"
        },
        {
            "background": "#002B36",
            "black": "#002B36",
            "blue": "#268BD2",
            "brightBlack": "#073642",
            "brightBlue": "#839496",
            "brightCyan": "#93A1A1",
            "brightGreen": "#586E75",
            "brightPurple": "#6C71C4",
            "brightRed": "#CB4B16",
            "brightWhite": "#FDF6E3",
            "brightYellow": "#657B83",
            "cursorColor": "#FFFFFF",
            "cyan": "#2AA198",
            "foreground": "#839496",
            "green": "#859900",
            "name": "Solarized Dark",
            "purple": "#D33682",
            "red": "#DC322F",
            "selectionBackground": "#FFFFFF",
            "white": "#EEE8D5",
            "yellow": "#B58900"
        },
        {
            "background": "#FDF6E3",
            "black": "#002B36",
            "blue": "#268BD2",
            "brightBlack": "#073642",
            "brightBlue": "#839496",
            "brightCyan": "#93A1A1",
            "brightGreen": "#586E75",
            "brightPurple": "#6C71C4",
            "brightRed": "#CB4B16",
            "brightWhite": "#FDF6E3",
            "brightYellow": "#657B83",
            "cursorColor": "#002B36",
            "cyan": "#2AA198",
            "foreground": "#657B83",
            "green": "#859900",
            "name": "Solarized Light",
            "purple": "#D33682",
            "red": "#DC322F",
            "selectionBackground": "#FFFFFF",
            "white": "#EEE8D5",
            "yellow": "#B58900"
        },
        {
            "background": "#000000",
            "black": "#000000",
            "blue": "#3465A4",
            "brightBlack": "#555753",
            "brightBlue": "#729FCF",
            "brightCyan": "#34E2E2",
            "brightGreen": "#8AE234",
            "brightPurple": "#AD7FA8",
            "brightRed": "#EF2929",
            "brightWhite": "#EEEEEC",
            "brightYellow": "#FCE94F",
            "cursorColor": "#FFFFFF",
            "cyan": "#06989A",
            "foreground": "#D3D7CF",
            "green": "#4E9A06",
            "name": "Tango Dark",
            "purple": "#75507B",
            "red": "#CC0000",
            "selectionBackground": "#FFFFFF",
            "white": "#D3D7CF",
            "yellow": "#C4A000"
        },
        {
            "background": "#FFFFFF",
            "black": "#000000",
            "blue": "#3465A4",
            "brightBlack": "#555753",
            "brightBlue": "#729FCF",
            "brightCyan": "#34E2E2",
            "brightGreen": "#8AE234",
            "brightPurple": "#AD7FA8",
            "brightRed": "#EF2929",
            "brightWhite": "#EEEEEC",
            "brightYellow": "#FCE94F",
            "cursorColor": "#000000",
            "cyan": "#06989A",
            "foreground": "#555753",
            "green": "#4E9A06",
            "name": "Tango Light",
            "purple": "#75507B",
            "red": "#CC0000",
            "selectionBackground": "#FFFFFF",
            "white": "#D3D7CF",
            "yellow": "#C4A000"
        },
        {
            "background": "#000000",
            "black": "#000000",
            "blue": "#000080",
            "brightBlack": "#808080",
            "brightBlue": "#0000FF",
            "brightCyan": "#00FFFF",
            "brightGreen": "#00FF00",
            "brightPurple": "#FF00FF",
            "brightRed": "#FF0000",
            "brightWhite": "#FFFFFF",
            "brightYellow": "#FFFF00",
            "cursorColor": "#FFFFFF",
            "cyan": "#008080",
            "foreground": "#C0C0C0",
            "green": "#008000",
            "name": "Vintage",
            "purple": "#800080",
            "red": "#800000",
            "selectionBackground": "#FFFFFF",
            "white": "#C0C0C0",
            "yellow": "#808000"
        }
    ],
    "themes": [],
    "windowingBehavior": "useExisting"
}
'@

# call "main" function
Do_CFConfigureW11