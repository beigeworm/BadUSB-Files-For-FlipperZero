
<# ================================================ ICON REARRANGER PRANK ========================================================

SYNOPSIS
This script hijacks the mouse and continuously minimizees all windows and drags around the desktop attempting to rearrange icons!

USAGE
1. Run the script.
2. Hold down the Escape key for 3 seconds to exit the script.

#>

# Hide the powershell console (1 = yes)
$hide = 1

# Code to hide the console on Windows 10 and 11
if ($hide -eq 1){
    $Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    $Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
    $hwnd = (Get-Process -PID $pid).MainWindowHandle
    
    if ($hwnd -ne [System.IntPtr]::Zero) {
        $Type::ShowWindowAsync($hwnd, 0)
    }
    else {
        $Host.UI.RawUI.WindowTitle = 'hideme'
        $Proc = (Get-Process | Where-Object { $_.MainWindowTitle -eq 'hideme' })
        $hwnd = $Proc.MainWindowHandle
        $Type::ShowWindowAsync($hwnd, 0)
    }
}



$iconmove = {

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, out RECT pvParam, int fWinIni);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public const int SPI_GETWORKAREA = 0x0030;
}
"@

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Mouse {
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    public const int LEFTDOWN = 0x02;
    public const int LEFTUP   = 0x04;
}
"@

$apps = New-Object -ComObject Shell.Application

# Get safe desktop area
$rect = New-Object WinAPI+RECT
[WinAPI]::SystemParametersInfo([WinAPI]::SPI_GETWORKAREA, 0, [ref]$rect, 0)

$width  = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
$offsetX = $rect.Left
$offsetY = $rect.Top

# Grid
$cols = [Math]::Min(40, [Math]::Floor($width / 50))
$rows = [Math]::Min(16, [Math]::Floor($height / 50))

$cellW = [Math]::Floor($width / $cols)
$cellH = [Math]::Floor($height / $rows)

# Points
$points = for ($x=0; $x -lt $cols; $x++) {
    for ($y=0; $y -lt $rows; $y++) {
        [PSCustomObject]@{
            X = [int]($offsetX + $x * $cellW + $cellW/2)
            Y = [int]($offsetY + $y * $cellH + $cellH/2)
        }
    }
}

Write-Host "MICRO-DRAG MODE: $cols x $rows grid"

while ($true) {
    $start = Get-Random $points
    $end   = Get-Random $points

    # Move to icon
    [Mouse]::SetCursorPos($start.X, $start.Y)
    Start-Sleep -Milliseconds 40

    # Mouse down
    [Mouse]::mouse_event([Mouse]::LEFTDOWN, 0, 0, 0, 0)

    # CRITICAL: tiny movement to trigger drag
    [Mouse]::SetCursorPos($start.X + 5, $start.Y + 5)
    Start-Sleep -Milliseconds 20

    # Fast jump to destination
    [Mouse]::SetCursorPos($end.X, $end.Y)
    Start-Sleep -Milliseconds 20

    # Release
    [Mouse]::mouse_event([Mouse]::LEFTUP, 0, 0, 0, 0)

    Start-Sleep -Milliseconds 40

    $apps.MinimizeAll()
}

}




Start-Job -ScriptBlock $iconmove


# Exit the script when the Escape key is held down for 3 seconds or more
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Keyboard{
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}

"@
$VK_ESCAPE = 0x1B
$startTime = $null
while ($true) {
    Start-Sleep -M 100
    $isEscapePressed = [Keyboard]::GetAsyncKeyState($VK_ESCAPE) -lt 0
    if ($isEscapePressed) {
        if (-not $startTime) {
            $startTime = Get-Date
        }
        $elapsedTime = (Get-Date) - $startTime
        if ($elapsedTime.TotalSeconds -ge 3) {
            exit
        }
    } else {
        $startTime = $null
    }
}
