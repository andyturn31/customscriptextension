<#
.SYNOPSIS
  This script is used to set regional and language settings in Windows Server 2019 or 2022.
  The script is stored in a public ADO repo, and is referenced by a custom script extension in the Virtual_Machine template spec.
  Language Pack files are also stored in the same ADO repo.
  SCHEDULE: None
#>

## Settings
$language = "en-GB"
$geoid = "242"
$logFile = "C:\Windows\Temp\customextension-regionlang.log"
$xmloutfile = "C:\Windows\Temp\Lng.xml"
$caboutfile = "c:\Windows\temp\langpack.cab"
$windowsVersion = (Get-ComputerInfo | Select-Object -ExpandProperty WindowsProductName)
if ($windowsVersion -like "*2022*") { $downloadUri = "https://at3459scriptsa.blob.core.windows.net/2022/Microsoft-Windows-Server-Language-Pack_x64_en-gb.cab" }
elseif ($windowsVersion -like "*2019*") { $downloadUri = "https://at3459scriptsa.blob.core.windows.net/2019/Microsoft-Windows-Server-Language-Pack_x64_en-gb.cab" }

## Start logging
Start-Transcript -Path $logFile -Append

## Set region and language settings
try {
  Write-Verbose "Setting culture to $($language)" -Verbose
  Set-Culture -CultureInfo $language
  Get-Culture
  
  Write-Verbose "Setting system locale to $($language)" -Verbose
  Set-WinSystemLocale -SystemLocale $language
  Get-WinSystemLocale

  Write-Verbose "Setting home location to $($language)" -Verbose
  Set-WinHomeLocation -GeoID $geoid
  Get-WinHomeLocation

  Write-Verbose "Download language pack for $($language)" -Verbose
  Invoke-WebRequest -Uri $downloadUri -OutFile $caboutfile

  Write-Verbose "Install language pack for $($language)" -Verbose
  cmd /c lpksetup /i * /p $caboutfile

  Write-Verbose "Setting user language list to $($language)" -Verbose
  Set-WinUserLanguageList -LanguageList $language -Force

  Write-Verbose "Setting UI language override to $($language)" -Verbose
  Set-WinUILanguageOverride -Language $language

  # copy settings to system and default user
  $xmlStr = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
    <!--User List-->
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToSystemAcct="true" CopySettingsToDefaultUserAcct="true" /> 
    </gs:UserList>

    <!--User Locale-->
    <gs:UserLocale> 
        <gs:Locale Name="$($language)" SetAsCurrent="true" ResetAllSettings="true"/>
    </gs:UserLocale>

    <gs:MUILanguagePreferences>
        <gs:MUILanguage Value="$($language)"/>
        <!--<gs:MUIFallback Value="en-US"/>-->
    </gs:MUILanguagePreferences>

</gs:GlobalizationServices>
"@

  $xmlStr | Out-File $xmloutfile -Force -Encoding ascii
  Write-Verbose "Copy language settings with control.exe" -Verbose
  control.exe "intl.cpl,,/f:""$($xmloutfile)"""
}

catch {
  Write-Error "An error occurred: $_"
}

# Cleanup
Write-Verbose "Clear downloaded files" -Verbose
Remove-Item $caboutfile, $xmloutfile -ErrorAction SilentlyContinue

## Stop logging
Stop-Transcript