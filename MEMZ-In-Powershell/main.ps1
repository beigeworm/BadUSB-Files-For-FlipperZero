<# ================================================ POWERSHELL MEMZ PRANK ========================================================

SYNOPSIS
This script displays various screen effects similar to the classic MEMZ trojan (Non-Destructive).
Also randomly plays the Windows Chord.wav sound endlessly

USAGE
1. Run the script.
2. Hold down the Escape key for 5 seconds to exit the script.

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

$mainjob = {


# Create the balloon popup (bottom right)
$baloonPopup = {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Warning
    $notify.Visible = $true
    $balloonTipTitle = "System Error (0x00060066e)"
    $balloonTipText = "WARNING! - Your system is fucked!"
    $notify.ShowBalloonTip(30000, $balloonTipTitle, $balloonTipText, [System.Windows.Forms.ToolTipIcon]::WARNING)
}

# Paint error icons wherever the mouse is located
$errorIcons = {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms  
    $desktopHandle = [System.IntPtr]::Zero
    $graphics = [System.Drawing.Graphics]::FromHwnd($desktopHandle)
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\DFDWiz.exe")  
    function Get-MousePosition {
        $point = [System.Windows.Forms.Cursor]::Position
        return $point
    }   
    while ($true) {
        $mousePosition = Get-MousePosition
        $graphics.DrawIcon($icon, $mousePosition.X, $mousePosition.Y)
        Start-Sleep -Milliseconds 50
    }
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.Dispose()
    $icon.Dispose()
}

# Take a snapshot of the desktop and paste blocks in random places
$screenBlocks = {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $File = "$env:temp\screen.png"
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $Width = $Screen.Width
    $Height = $Screen.Height
    $Left = $Screen.Left
    $Top = $Screen.Top
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
    $bitmap.Save($File, [System.Drawing.Imaging.ImageFormat]::png)
    $savedImage = [System.Drawing.Image]::FromFile($File)
    $desktopHandle = [System.IntPtr]::Zero
    $graphics = [System.Drawing.Graphics]::FromHwnd($desktopHandle)
    $random = New-Object System.Random    
    function Get-RandomSize {
        return $random.Next(100, 500)
    }    
    function Get-RandomPosition {
        param ([int]$rectWidth,[int]$rectHeight)
        $x = $random.Next(0, $Width - $rectWidth)
        $y = $random.Next(0, $Height - $rectHeight)
        return [PSCustomObject]@{X = $x; Y = $y}
    }
    function Invert-Colors {
        param ([System.Drawing.Bitmap]$bitmap,[System.Drawing.Rectangle]$rect)
        for ($x = $rect.X; $x -lt $rect.X + $rect.Width; $x++) {
            for ($y = $rect.Y; $y -lt $rect.Y + $rect.Height; $y++) {
                $pixelColor = $bitmap.GetPixel($x, $y)
                $invertedColor = [System.Drawing.Color]::FromArgb(255, 255 - $pixelColor.R, 255 - $pixelColor.G, 255 - $pixelColor.B)
                $bitmap.SetPixel($x, $y, $invertedColor)
            }
        }
    }
    while ($true) {
        $rectWidth = Get-RandomSize
        $rectHeight = Get-RandomSize
        $srcX = $random.Next(0, $savedImage.Width - $rectWidth)
        $srcY = $random.Next(0, $savedImage.Height - $rectHeight)
        $destPosition = Get-RandomPosition -rectWidth $rectWidth -rectHeight $rectHeight
        $srcRect = New-Object System.Drawing.Rectangle $srcX, $srcY, $rectWidth, $rectHeight
        $destRect = New-Object System.Drawing.Rectangle $destPosition.X, $destPosition.Y, $rectWidth, $rectHeight
        $graphics.DrawImage($savedImage, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        Start-Sleep -M 50
        $rectWidth = Get-RandomSize
        $rectHeight = Get-RandomSize
        $srcX = $random.Next(0, $savedImage.Width - $rectWidth)
        $srcY = $random.Next(0, $savedImage.Height - $rectHeight)
        $destPosition = Get-RandomPosition -rectWidth $rectWidth -rectHeight $rectHeight
        $srcRect = New-Object System.Drawing.Rectangle $srcX, $srcY, $rectWidth, $rectHeight
        $destRect = New-Object System.Drawing.Rectangle $destPosition.X, $destPosition.Y, $rectWidth, $rectHeight
        $srcBitmap = $savedImage.Clone($srcRect, $savedImage.PixelFormat)
        Invert-Colors -bitmap $srcBitmap -rect (New-Object System.Drawing.Rectangle 0, 0, $rectWidth, $rectHeight)
        $graphics.DrawImage($srcBitmap, $destRect)
        $srcBitmap.Dispose()
        Start-Sleep -M 50
    }    
    $savedImage.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
    $graphic.Dispose()
}

# Spam the Windows chord sound randomly
$SoundSpam = {
    $i = 250
    $random = New-Object System.Random
    while($true){
        Get-ChildItem C:\Windows\Media\ -File -Filter *hor*.wav | Select-Object -ExpandProperty Name | Foreach-Object { 
            Start-Sleep -M $i
            (New-Object Media.SoundPlayer "C:\WINDOWS\Media\$_").Play()
        }
        $i = $random.Next(100, 300)
    }
}

# Display "SYSTEM FAIL!" messages in random sizes everywhere
$failMessage = {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $Width = $screen.Bounds.Width
    $Height = $screen.Bounds.Height
    $desktopHandle = [System.IntPtr]::Zero
    $graphics = [System.Drawing.Graphics]::FromHwnd($desktopHandle)
    $random = New-Object System.Random
    function Get-RandomFontSize {
        return $random.Next(20, 101)
    }
    function Get-RandomPosition {
        param ([int]$textWidth,[int]$textHeight)
        $x = $random.Next(0, $Width - $textWidth)
        $y = $random.Next(0, $Height - $textHeight)
        return [PSCustomObject]@{X = $x; Y = $y}
    }
    $text = "SYSTEM FAIL!"
    $textColor = [System.Drawing.Color]::Red
    while ($true) {
        $fontSize = Get-RandomFontSize
        $font = New-Object System.Drawing.Font("Arial", $fontSize, [System.Drawing.FontStyle]::Bold)
        $textSize = $graphics.MeasureString($text, $font)
        $textWidth = [math]::Ceiling($textSize.Width)
        $textHeight = [math]::Ceiling($textSize.Height)
        $position = Get-RandomPosition -textWidth $textWidth -textHeight $textHeight
        $graphics.DrawString($text, $font, (New-Object System.Drawing.SolidBrush($textColor)), $position.X, $position.Y)
        $font.Dispose()
        Start-Sleep -M 250
    }
}

# Take a snapshot of the desktop and shrink towards the center
$screenmelt = {
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms 
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetDC(IntPtr hWnd);
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr CreateCompatibleDC(IntPtr hdc);
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr CreateCompatibleBitmap(IntPtr hdc, int nWidth, int nHeight);
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool BitBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight,
                                     IntPtr hdcSrc, int nXSrc, int nYSrc, uint dwRop);
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool DeleteDC(IntPtr hdc);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool ReleaseDC(IntPtr hWnd, IntPtr hDC);
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool DeleteObject(IntPtr hObject);
    public const int SRCCOPY = 0x00CC0020;
}
"@
    
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $Width = $Screen.Width
    $Height = $Screen.Height
    $Left = $Screen.Left
    $Top = $Screen.Top
    $desktopDC = [NativeMethods]::GetDC([IntPtr]::Zero)
    $memDC = [NativeMethods]::CreateCompatibleDC($desktopDC)
    $bitmap = [NativeMethods]::CreateCompatibleBitmap($desktopDC, $Width, $Height)
    [NativeMethods]::SelectObject($memDC, $bitmap)
    [NativeMethods]::BitBlt($memDC, 0, 0, $Width, $Height, $desktopDC, $Left, $Top, [NativeMethods]::SRCCOPY)
    $fallSpeed = 20
    $shrinkFactor = 0.96
    while($true){
        $currentOffsetX1 = 0
        $currentOffsetY1 = 0
        $currentWidth1 = $Width
        $currentHeight1 = $Height
        $currentOffsetX2 = $Width
        $currentOffsetY2 = $Height
        $currentWidth2 = $Width
        $currentHeight2 = $Height
        while ($currentOffsetX1 -lt $Width -and $currentOffsetY1 -lt $Height -and
               $currentOffsetX2 -gt 0 -and $currentOffsetY2 -gt 0) {
            $currentWidth1 = [math]::floor($currentWidth1 * $shrinkFactor)
            $currentHeight1 = [math]::floor($currentHeight1 * $shrinkFactor)
            $currentWidth2 = [math]::floor($currentWidth2 * $shrinkFactor)
            $currentHeight2 = [math]::floor($currentHeight2 * $shrinkFactor)
            [NativeMethods]::BitBlt($desktopDC, $currentOffsetX1, $currentOffsetY1, $currentWidth1, $currentHeight1,
                                    $memDC, 0, 0, [NativeMethods]::SRCCOPY)
            [NativeMethods]::BitBlt($desktopDC, $currentOffsetX2 - $currentWidth2, $currentOffsetY2 - $currentHeight2, $currentWidth2, $currentHeight2,
                                    $memDC, 0, 0, [NativeMethods]::SRCCOPY)
            $currentOffsetX1 += $fallSpeed
            $currentOffsetY1 += $fallSpeed
            $currentOffsetX2 -= $fallSpeed
            $currentOffsetY2 -= $fallSpeed
            Start-Sleep -Milliseconds 100
        }
    }
    [NativeMethods]::DeleteDC($memDC)
    [NativeMethods]::ReleaseDC([IntPtr]::Zero, $desktopDC)
    [NativeMethods]::DeleteObject($bitmap)
}



$mouseblock = {


Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Mouse {
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    public struct POINT {
        public int X;
        public int Y;
    }
}
"@

    # --- Settings ---
    $jitterRange = 3          # max wobble from anchor in pixels
    $delayMs = 30             # loop speed
    $userMoveThreshold = 4    # if cursor moved this much from our last output, treat as real user movement
    
    # --- State ---
    $p = New-Object Mouse+POINT
    [Mouse]::GetCursorPos([ref]$p) | Out-Null
    
    $anchorX = $p.X
    $anchorY = $p.Y
    
    $lastSetX = $p.X
    $lastSetY = $p.Y
    
    while ($true) {
        $p = New-Object Mouse+POINT
        [Mouse]::GetCursorPos([ref]$p) | Out-Null
    
        $currentX = $p.X
        $currentY = $p.Y
    
        # Detect likely real user movement:
        # if current cursor position differs enough from the last position we set,
        # assume the user moved the mouse and update the anchor
        $dxFromLastSet = $currentX - $lastSetX
        $dyFromLastSet = $currentY - $lastSetY
        $distFromLastSet = [Math]::Sqrt(($dxFromLastSet * $dxFromLastSet) + ($dyFromLastSet * $dyFromLastSet))
    
        if ($distFromLastSet -gt $userMoveThreshold) {
            $anchorX = $currentX
            $anchorY = $currentY
        }
    
        # Random jitter around the anchor, not around the already-jittered cursor
        $jx = Get-Random -Minimum (-$jitterRange) -Maximum ($jitterRange + 1)
        $jy = Get-Random -Minimum (-$jitterRange) -Maximum ($jitterRange + 1)
    
        $targetX = $anchorX + $jx
        $targetY = $anchorY + $jy
    
        [Mouse]::SetCursorPos($targetX, $targetY)
    
        $lastSetX = $targetX
        $lastSetY = $targetY
    
        Start-Sleep -Milliseconds $delayMs
    }



}


$soundblock = {



function New-RandomToneWav {
    param(
        [string]$Path,
        [int]$SampleRate = 44100,
        [int]$DurationSeconds = 10
    )

    $channels = 1
    $bits = 16
    $blockAlign = $channels * ($bits / 8)
    $byteRate = $SampleRate * $blockAlign
    $totalSamples = $SampleRate * $DurationSeconds
    $dataSize = $totalSamples * $blockAlign

    $fs = [System.IO.File]::Open($Path, 'Create')
    $bw = New-Object System.IO.BinaryWriter($fs)

    try {
        $bw.Write([Text.Encoding]::ASCII.GetBytes("RIFF"))
        $bw.Write([int](36 + $dataSize))
        $bw.Write([Text.Encoding]::ASCII.GetBytes("WAVE"))

        $bw.Write([Text.Encoding]::ASCII.GetBytes("fmt "))
        $bw.Write([int]16)
        $bw.Write([int16]1)
        $bw.Write([int16]$channels)
        $bw.Write([int]$SampleRate)
        $bw.Write([int]$byteRate)
        $bw.Write([int16]$blockAlign)
        $bw.Write([int16]$bits)

        $bw.Write([Text.Encoding]::ASCII.GetBytes("data"))
        $bw.Write([int]$dataSize)

        $phase1 = 0.0
        $phase2 = 0.0
        $freq1 = 900.0
        $freq2 = 1230.0
        $ampLfo = 0.0

        for ($i = 0; $i -lt $totalSamples; $i++) {

            # Main oscillator: much faster wandering
            $freq1 += ((Get-Random -Minimum -1000 -Maximum 1001) / 1000.0) * 8.0

            # Secondary oscillator: separate random walk
            $freq2 += ((Get-Random -Minimum -1000 -Maximum 1001) / 1000.0) * 11.0

            # Occasional nasty jumps
            if ((Get-Random -Minimum 0 -Maximum 1000) -lt 8) {
                $freq1 = Get-Random -Minimum 400 -Maximum 3200
            }
            if ((Get-Random -Minimum 0 -Maximum 1000) -lt 10) {
                $freq2 = Get-Random -Minimum 700 -Maximum 4200
            }

            # Clamp ranges
            if ($freq1 -lt 250)  { $freq1 = 250 }
            if ($freq1 -gt 3500) { $freq1 = 3500 }
            if ($freq2 -lt 300)  { $freq2 = 300 }
            if ($freq2 -gt 5000) { $freq2 = 5000 }

            $phase1 += 2.0 * [Math]::PI * $freq1 / $SampleRate
            $phase2 += 2.0 * [Math]::PI * $freq2 / $SampleRate

            if ($phase1 -gt 2.0 * [Math]::PI) { $phase1 -= 2.0 * [Math]::PI }
            if ($phase2 -gt 2.0 * [Math]::PI) { $phase2 -= 2.0 * [Math]::PI }

            # Oscillator 1: sine
            $sine1 = [Math]::Sin($phase1)

            # Oscillator 2: square-ish harsh tone
            $sine2 = [Math]::Sin($phase2)
            if ($sine2 -ge 0) { $square2 = 1.0 } else { $square2 = -1.0 }

            # Fast tremolo / amplitude wobble
            $ampLfo += 2.0 * [Math]::PI * 14.0 / $SampleRate
            if ($ampLfo -gt 2.0 * [Math]::PI) { $ampLfo -= 2.0 * [Math]::PI }
            $amp = 0.45 + (0.35 * [Math]::Sin($ampLfo))

            # Tiny bit of random grit
            $noise = ((Get-Random -Minimum -1000 -Maximum 1001) / 1000.0) * 0.10

            # Mix
            $v = ($sine1 * 0.45) + ($square2 * 0.45) + $noise
            $v *= $amp

            if ($v -gt 1.0)  { $v = 1.0 }
            if ($v -lt -1.0) { $v = -1.0 }

            $pcm = [int16]($v * 28000)
            $bw.Write([int16]$pcm)
        }
    }
    finally {
        $bw.Close()
        $fs.Close()
    }
}

$path = Join-Path $env:TEMP "bg_osc.wav"
New-RandomToneWav -Path $path

$script:player = New-Object System.Media.SoundPlayer
$script:player.SoundLocation = $path
$script:player.Load()
$script:player.PlayLooping()

Write-Host "Playing in background."
Write-Host "Press Ctrl+C to stop."

while ($true) {
    Start-Sleep -Seconds 1
}


}


$screenmelt = {
Add-Type -AssemblyName System.Windows.Forms

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetDC(IntPtr hWnd);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr CreateCompatibleDC(IntPtr hdc);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr CreateCompatibleBitmap(IntPtr hdc, int nWidth, int nHeight);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool BitBlt(
        IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight,
        IntPtr hdcSrc, int nXSrc, int nYSrc, uint dwRop
    );

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool StretchBlt(
        IntPtr hdcDest, int xDest, int yDest, int wDest, int hDest,
        IntPtr hdcSrc, int xSrc, int ySrc, int wSrc, int hSrc,
        uint rop
    );

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool DeleteDC(IntPtr hdc);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool DeleteObject(IntPtr hObject);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

    public const uint SRCCOPY = 0x00CC0020;
}
"@

$screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
$width  = $screen.Width
$height = $screen.Height
$left   = $screen.Left
$top    = $screen.Top

$desktopDC = [IntPtr]::Zero
$srcDC     = [IntPtr]::Zero
$workDC    = [IntPtr]::Zero
$srcBmp    = [IntPtr]::Zero
$workBmp   = [IntPtr]::Zero
$srcOld    = [IntPtr]::Zero
$workOld   = [IntPtr]::Zero


try {
    $desktopDC = [NativeMethods]::GetDC([IntPtr]::Zero)

    $srcDC   = [NativeMethods]::CreateCompatibleDC($desktopDC)
    $workDC  = [NativeMethods]::CreateCompatibleDC($desktopDC)
    $srcBmp  = [NativeMethods]::CreateCompatibleBitmap($desktopDC, $width, $height)
    $workBmp = [NativeMethods]::CreateCompatibleBitmap($desktopDC, $width, $height)

    $srcOld  = [NativeMethods]::SelectObject($srcDC,  $srcBmp)
    $workOld = [NativeMethods]::SelectObject($workDC, $workBmp)

    # Initial desktop capture
    [void][NativeMethods]::BitBlt(
        $srcDC, 0, 0, $width, $height,
        $desktopDC, $left, $top, [NativeMethods]::SRCCOPY
    )

    $strips = New-Object System.Collections.Generic.List[object]
    $x = 0
    while ($x -lt $width) {
        $stripWidth = Get-Random -Minimum 1 -Maximum 4
        if ($x + $stripWidth -gt $width) { $stripWidth = $width - $x }

        $strips.Add([pscustomobject]@{
            X          = $x
            Width      = $stripWidth
            OffsetY    = [double](Get-Random -Minimum -1 -Maximum 1)
            Speed      = (Get-Random -Minimum 0.06 -Maximum 0.09)
            Accel      = (Get-Random -Minimum 0.003 -Maximum 0.008)
            Sway       = (Get-Random -Minimum 2.0 -Maximum 14.0)
            Phase      = (Get-Random -Minimum 0.0 -Maximum 6.28318)
            PhaseRate  = (Get-Random -Minimum 0.04 -Maximum 0.20)
            MeltBias   = (Get-Random -Minimum 0.78 -Maximum 0.98)
            Split      = Get-Random -Minimum 1 -Maximum 7
            RippleAmp  = (Get-Random -Minimum 0.0 -Maximum 4.0)
        })

        $x += $stripWidth
    }

    $frame = 0
    $heatFrames = 90

    Write-Host "Liquefy effect running. Press Esc to stop."

    while ($true) {

        # Work buffer starts from source buffer each frame
        [void][NativeMethods]::BitBlt(
            $workDC, 0, 0, $width, $height,
            $srcDC, 0, 0, [NativeMethods]::SRCCOPY
        )

        $globalRipple = [Math]::Sin($frame * 0.10) * 6.0

        foreach ($s in $strips) {
            $s.Speed += $s.Accel
            if ($s.Speed -gt 6) { $s.Speed = 6 }

            if ((Get-Random -Minimum 0 -Maximum 1000) -lt 2) {
                $s.Speed += Get-Random -Minimum 0.05 -Maximum 0.2
            }

            $s.OffsetY += $s.Speed
            $s.Phase += $s.PhaseRate

            if ($s.OffsetY -gt ($height + 120)) {
                $s.OffsetY   = Get-Random -Minimum -0.1 -Maximum -0.2
                $s.Speed     = Get-Random -Minimum 0.6 -Maximum 2.4
                $s.Accel     = Get-Random -Minimum 0.03 -Maximum 0.18
                $s.Sway      = Get-Random -Minimum 2.0 -Maximum 14.0
                $s.Phase     = Get-Random -Minimum 0.0 -Maximum 6.28318
                $s.PhaseRate = Get-Random -Minimum 0.04 -Maximum 0.20
                $s.MeltBias  = Get-Random -Minimum 0.78 -Maximum 0.98
                $s.Split     = Get-Random -Minimum 1 -Maximum 7
                $s.RippleAmp = Get-Random -Minimum 0.0 -Maximum 4.0
            }

            $heatRamp = 1.0
            if ($frame -lt $heatFrames) {
                $heatRamp = $frame / [double]$heatFrames
            }

            $rippleX = [Math]::Sin(($s.X * 0.04) + ($frame * 0.18) + $s.Phase) * ($s.RippleAmp + $globalRipple) * $heatRamp
            $sagX    = [Math]::Sin($s.Phase) * $s.Sway
            $destX   = [int]($s.X + $rippleX + $sagX)
            $destY   = [int]$s.OffsetY

            if ($destY -lt 0) { $destY = 0 }
            if ($destY -ge $height) { continue }

            $destW = [int][Math]::Max(1, $s.Width)
            if ($destX -lt 0) { $destX = 0 }
            if ($destX + $destW -gt $width) { $destW = $width - $destX }
            if ($destW -le 0) { continue }

            $destH = $height - $destY
            if ($destH -le 0) { continue }

            $srcH = [int][Math]::Max(8, $height * $s.MeltBias)

            # main melt body
            [void][NativeMethods]::StretchBlt(
                $workDC,
                $destX, $destY, $destW, $destH,
                $srcDC,
                $s.X, 0, $s.Width, $srcH,
                [NativeMethods]::SRCCOPY
            )

            # RGB-ish split by drawing slight offset copies
            $split = [int]$s.Split
            [void][NativeMethods]::StretchBlt(
                $workDC,
                $destX - $split, $destY, $destW, $destH,
                $srcDC,
                $s.X, 0, $s.Width, [int]($srcH * 0.99),
                [NativeMethods]::SRCCOPY
            )

            [void][NativeMethods]::StretchBlt(
                $workDC,
                $destX + $split, $destY + 1, $destW, $destH,
                $srcDC,
                $s.X, 0, $s.Width, [int]($srcH * 0.97),
                [NativeMethods]::SRCCOPY
            )

            # top smear
            if ($destY -gt 3) {
                $smearH = [Math]::Min(10, $destH)
                [void][NativeMethods]::StretchBlt(
                    $workDC,
                    $destX, $destY - $smearH, $destW, $smearH,
                    $srcDC,
                    $s.X, 0, $s.Width, [Math]::Max(2, [int]($smearH * 0.4)),
                    [NativeMethods]::SRCCOPY
                )
            }
        }

        # Draw work buffer to screen
        [void][NativeMethods]::BitBlt(
            $desktopDC, $left, $top, $width, $height,
            $workDC, 0, 0, [NativeMethods]::SRCCOPY
        )

        # Recursive self-melt: periodically recapture the distorted result
        if (($frame % 3) -eq 0) {
            [void][NativeMethods]::BitBlt(
                $srcDC, 0, 0, $width, $height,
                $desktopDC, $left, $top, [NativeMethods]::SRCCOPY
            )
        }

        $frame++
        Start-Sleep -Milliseconds 18
    }
}
finally {
    if ($srcDC -ne [IntPtr]::Zero -and $srcOld -ne [IntPtr]::Zero) {
        [void][NativeMethods]::SelectObject($srcDC, $srcOld)
    }
    if ($workDC -ne [IntPtr]::Zero -and $workOld -ne [IntPtr]::Zero) {
        [void][NativeMethods]::SelectObject($workDC, $workOld)
    }
    if ($srcBmp -ne [IntPtr]::Zero) {
        [void][NativeMethods]::DeleteObject($srcBmp)
    }
    if ($workBmp -ne [IntPtr]::Zero) {
        [void][NativeMethods]::DeleteObject($workBmp)
    }
    if ($srcDC -ne [IntPtr]::Zero) {
        [void][NativeMethods]::DeleteDC($srcDC)
    }
    if ($workDC -ne [IntPtr]::Zero) {
        [void][NativeMethods]::DeleteDC($workDC)
    }
    if ($desktopDC -ne [IntPtr]::Zero) {
        [void][NativeMethods]::ReleaseDC([IntPtr]::Zero, $desktopDC)
    }
}

}


$party = {

    Add-Type -AssemblyName System.Windows.Forms
    
    $duration = 10000
    $interval = 100  
    $color1 = "Black"
    $color2 = "Green"
    $color3 = "Red"
    $color4 = "Yellow"
    $color5 = "Blue"
    $color6 = "white"
    
    $startTime = Get-Date
    
    while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
        $toggle = 1
        while ($toggle -lt 7){
        $form = New-Object System.Windows.Forms.Form
        $form.BackColor = $currentColor
        $form.FormBorderStyle = "None"
        $form.WindowState = "Maximized"
        $form.TopMost = $true
            if ($toggle -eq 1) {
                $currentColor = $color1
            }
            if ($toggle -eq 2) {
                $currentColor = $color2
            }
            if ($toggle -eq 3) {
                $currentColor = $color3
            }
            if ($toggle -eq 4) {
                $currentColor = $color4
            }
            if ($toggle -eq 5) {
                $currentColor = $color5
            }
            if ($toggle -eq 6) {
                $currentColor = $color6
            }
        $form.BackColor = $currentColor
        $form.Show()
        Start-Sleep -Milliseconds $interval
        $form.Close()
        $toggle++
        }
    }
    

}


    # Start jobs intermitently
    
    sleep 5
    
    Start-Job -ScriptBlock $baloonPopup
    Start-Job -ScriptBlock $mouseblock

    sleep 10

    Start-Job -ScriptBlock $errorIcons
    
    sleep 10
    
    Start-Job -ScriptBlock $screenBlocks
    
    sleep 5
    
    Start-Job -ScriptBlock $SoundSpam
    Start-Job -ScriptBlock $failMessage
   
    Start-Job -ScriptBlock $soundblock
    
    Sleep 10
    
    Start-Job -ScriptBlock $screenmelt
    
    Sleep 20
    
    Start-Job -ScriptBlock $party

    pause
}

Start-Job -ScriptBlock $mainjob

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

