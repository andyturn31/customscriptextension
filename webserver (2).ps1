# 64-bit process check
if (-not [System.Environment]::Is64BitProcess) {
  Write-Host "Not 64-bit process. Restart in 64-bit environment"

  # start new PowerShell as x64 bit process, wait for it and gather exit code and standard error output
  $sysNativePowerShell = "$($PSHOME.ToLower().Replace("syswow64", "sysnative"))\powershell.exe"

  $pinfo = New-Object System.Diagnostics.ProcessStartInfo
  $pinfo.FileName = $sysNativePowerShell
  $pinfo.Arguments = "-ex bypass -file `"$PSCommandPath`""
  $pinfo.RedirectStandardError = $true
  $pinfo.RedirectStandardOutput = $true
  $pinfo.CreateNoWindow = $true
  $pinfo.UseShellExecute = $false
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $pinfo
  $p.Start() | Out-Null

  $exitCode = $p.ExitCode

  $stderr = $p.StandardError.ReadToEnd()

  if ($stderr) { Write-Error -Message $stderr }

  exit $exitCode
}

# Define the path for the log file
$logFile = "C:\Windows\Temp\customextension.log"

# Define the path for the xml file
$outFile = "C:\Windows\Temp\Lng.xml"

# Start logging to the file
Start-Transcript -Path $logFile -Append

# Set culture and language settings
try {
  Write-Verbose "Installing IIS" -Verbose
  Install-WindowsFeature -Name Web-Server

  Write-Verbose "Setting culture to en-GB" -Verbose
  Set-Culture -CultureInfo "en-GB"
  
  Write-Verbose "Setting system locale to en-GB" -Verbose
  Set-WinSystemLocale -SystemLocale "en-GB"

  Write-Verbose "Setting home location to UK" -Verbose
  Set-WinHomeLocation -GeoID 242

  Write-Verbose "Install language pack for en-GB" -Verbose
  Invoke-WebRequest -Uri "https://at3459scriptsa.blob.core.windows.net/2022/Microsoft-Windows-Server-Language-Pack_x64_en-gb.cab" -OutFile c:\Windows\temp\Microsoft-Windows-Server-Language-Pack_x64_en-gb.cab
  cmd /c lpksetup /i en-gb /p "c:\Windows\temp\Microsoft-Windows-Server-Language-Pack_x64_en-gb.cab"

  Write-Verbose "Setting user language list to en-GB" -Verbose
  Set-WinUserLanguageList -LanguageList en-GB -Force

  Write-Verbose "Setting UI language override to en-GB" -Verbose
  Set-WinUILanguageOverride -Language en-GB

  $xmlStr = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
    <!--User List-->
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToSystemAcct="true" CopySettingsToDefaultUserAcct="true" /> 
    </gs:UserList>

    <!--User Locale-->
    <gs:UserLocale> 
        <gs:Locale Name="en-GB" SetAsCurrent="true" ResetAllSettings="true"/>
    </gs:UserLocale>

    <gs:MUILanguagePreferences>
        <gs:MUILanguage Value="en-GB"/>
        <!--<gs:MUIFallback Value="en-US"/>-->
    </gs:MUILanguagePreferences>

</gs:GlobalizationServices>
"@

  $xmlStr | Out-File $outFile -Force -Encoding ascii

  # Use this copy settings to system and default user 
  Write-Verbose "Copy language settings with control.exe" -Verbose
  control.exe "intl.cpl,,/f:""$($outFile)"""

}
catch {
  Write-Error "An error occurred: $_"
}

# Stop logging
Stop-Transcript