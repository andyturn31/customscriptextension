# Set Variables
$language = "en-GB"
$geoid = "242"
$logFile = "C:\Windows\Temp\customextension.log"
$xmloutfile = "C:\Windows\Temp\Lng.xml"
$windowsVersion = (Get-ComputerInfo | Select-Object -ExpandProperty WindowsProductName)
if ($windowsVersion -like "*2022*") {$downloadUri = "https://at3459scriptsa.blob.core.windows.net/2022/Microsoft-Windows-Server-Language-Pack_x64_en-gb.cab"}
elseif ($windowsVersion -like "*2019*") {$downloadUri = "https://at3459scriptsa.blob.core.windows.net/2019/Microsoft-Windows-Server-Language-Pack_x64_en-gb.cab"}

# Start logging to the file
Start-Transcript -Path $logFile -Append

# Set culture and language settings
try {
  Write-Verbose "Setting culture to $($language)" -Verbose
  Set-Culture -CultureInfo $language
  
  Write-Verbose "Setting system locale to $($language)" -Verbose
  Set-WinSystemLocale -SystemLocale $language

  Write-Verbose "Setting home location to $($language)" -Verbose
  Set-WinHomeLocation -GeoID $geoid

  Write-Verbose "Install language pack for $($language)" -Verbose
  Invoke-WebRequest -Uri $downloadUri -OutFile c:\Windows\temp\langpack.cab
  cmd /c lpksetup /i * /p "c:\Windows\temp\langpack.cab"

  Write-Verbose "Setting user language list to $($language)" -Verbose
  Set-WinUserLanguageList -LanguageList $language -Force

  Write-Verbose "Setting UI language override to $($language)" -Verbose
  Set-WinUILanguageOverride -Language $language

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

  # Use this copy settings to system and default user 
  Write-Verbose "Copy language settings with control.exe" -Verbose
  control.exe "intl.cpl,,/f:""$($xmloutfile)"""

}
catch {
  Write-Error "An error occurred: $_"
}

# Stop logging
Stop-Transcript