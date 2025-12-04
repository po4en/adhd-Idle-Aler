Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Idle Alert"
$form.Size = New-Object System.Drawing.Size(460,280)
$form.StartPosition = "CenterScreen"

# --- Threshold minutes ---
$labelThreshMin = New-Object System.Windows.Forms.Label
$labelThreshMin.Text = "Idle threshold:"
$labelThreshMin.Location = New-Object System.Drawing.Point(10,20)
$labelThreshMin.AutoSize = $true
$form.Controls.Add($labelThreshMin)

$textThreshMin = New-Object System.Windows.Forms.TextBox
$textThreshMin.Location = New-Object System.Drawing.Point(110,18)
$textThreshMin.Size = New-Object System.Drawing.Size(50,20)
$textThreshMin.Text = "1"
$form.Controls.Add($textThreshMin)

$labelThreshMinUnit = New-Object System.Windows.Forms.Label
$labelThreshMinUnit.Text = "min"
$labelThreshMinUnit.Location = New-Object System.Drawing.Point(165,20)
$labelThreshMinUnit.AutoSize = $true
$form.Controls.Add($labelThreshMinUnit)

# Threshold seconds
$textThreshSec = New-Object System.Windows.Forms.TextBox
$textThreshSec.Location = New-Object System.Drawing.Point(210,18)
$textThreshSec.Size = New-Object System.Drawing.Size(60,20)
$textThreshSec.Text = "60"
$form.Controls.Add($textThreshSec)

$labelThreshSecUnit = New-Object System.Windows.Forms.Label
$labelThreshSecUnit.Text = "sec"
$labelThreshSecUnit.Location = New-Object System.Drawing.Point(275,20)
$labelThreshSecUnit.AutoSize = $true
$form.Controls.Add($labelThreshSecUnit)

# --- Repeat minutes ---
$labelRepeatMin = New-Object System.Windows.Forms.Label
$labelRepeatMin.Text = "Repeat every:"
$labelRepeatMin.Location = New-Object System.Drawing.Point(10,50)
$labelRepeatMin.AutoSize = $true
$form.Controls.Add($labelRepeatMin)

$textRepeatMin = New-Object System.Windows.Forms.TextBox
$textRepeatMin.Location = New-Object System.Drawing.Point(110,48)
$textRepeatMin.Size = New-Object System.Drawing.Size(50,20)
$textRepeatMin.Text = "0"
$form.Controls.Add($textRepeatMin)

$labelRepeatMinUnit = New-Object System.Windows.Forms.Label
$labelRepeatMinUnit.Text = "min"
$labelRepeatMinUnit.Location = New-Object System.Drawing.Point(165,50)
$labelRepeatMinUnit.AutoSize = $true
$form.Controls.Add($labelRepeatMinUnit)

$textRepeatSec = New-Object System.Windows.Forms.TextBox
$textRepeatSec.Location = New-Object System.Drawing.Point(210,48)
$textRepeatSec.Size = New-Object System.Drawing.Size(60,20)
$textRepeatSec.Text = "30"
$form.Controls.Add($textRepeatSec)

$labelRepeatSecUnit = New-Object System.Windows.Forms.Label
$labelRepeatSecUnit.Text = "sec (0 = once)"
$labelRepeatSecUnit.Location = New-Object System.Drawing.Point(275,50)
$labelRepeatSecUnit.AutoSize = $true
$form.Controls.Add($labelRepeatSecUnit)

# Buttons
$buttonStart = New-Object System.Windows.Forms.Button
$buttonStart.Text = "Start"
$buttonStart.Location = New-Object System.Drawing.Point(40,90)
$form.Controls.Add($buttonStart)

$buttonStop = New-Object System.Windows.Forms.Button
$buttonStop.Text = "Stop"
$buttonStop.Location = New-Object System.Drawing.Point(150,90)
$buttonStop.Enabled = $false
$form.Controls.Add($buttonStop)

# Status
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status: Stopped"
$statusLabel.Location = New-Object System.Drawing.Point(10,140)
$statusLabel.AutoSize = $true
$form.Controls.Add($statusLabel)

$countdownLabel = New-Object System.Windows.Forms.Label
$countdownLabel.Text = "Countdown: -"
$countdownLabel.Location = New-Object System.Drawing.Point(10,170)
$countdownLabel.AutoSize = $true
$form.Controls.Add($countdownLabel)

# ---- Idle detector code ----
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class IdleTimeHelper {
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetIdleTimeMs() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(lii);
        GetLastInputInfo(ref lii);
        return (uint)Environment.TickCount - lii.dwTime;
    }
}
"@

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000

$script:thresholdSec = 60
$script:repeatSec = 30
$script:firstAlertDone = $false
$script:lastBeepIdleSec = 0

function Update-CountdownLabel {
    param([int]$idleSec)

    if (-not $script:firstAlertDone) {
        $remaining = $script:thresholdSec - $idleSec
        if ($remaining -lt 0) { $remaining = 0 }
        $countdownLabel.Text = "Countdown to first alert: $remaining sec"
    } elseif ($script:repeatSec -gt 0) {
        $sinceLast = $idleSec - $script:lastBeepIdleSec
        $remaining = $script:repeatSec - $sinceLast
        if ($remaining -lt 0) { $remaining = 0 }
        $countdownLabel.Text = "Countdown to next alert: $remaining sec"
    } else {
        $countdownLabel.Text = "Countdown: - (one-time alert)"
    }
}

# sync minutes -> seconds
$textThreshMin.Add_TextChanged({
    $m = 0
    if ([int]::TryParse($textThreshMin.Text, [ref]$m) -and $m -ge 0) {
        $textThreshSec.Text = ($m * 60).ToString()
    }
})
$textRepeatMin.Add_TextChanged({
    $m = 0
    if ([int]::TryParse($textRepeatMin.Text, [ref]$m) -and $m -ge 0) {
        $textRepeatSec.Text = ($m * 60).ToString()
    }
})

# Start
$buttonStart.Add_Click({
    $tSec = 0; $rSec = 0

    if (-not [int]::TryParse($textThreshSec.Text, [ref]$tSec) -or $tSec -le 0) {
        [System.Windows.Forms.MessageBox]::Show("Threshold seconds must be > 0.")
        return
    }
    if (-not [int]::TryParse($textRepeatSec.Text, [ref]$rSec) -or $rSec -lt 0) {
        [System.Windows.Forms.MessageBox]::Show("Repeat seconds must be >= 0.")
        return
    }

    $script:thresholdSec = $tSec
    $script:repeatSec = $rSec
    $script:firstAlertDone = $false
    $script:lastBeepIdleSec = 0

    $statusLabel.Text = "Status: Running (threshold=$script:thresholdSec sec, repeat=$script:repeatSec sec)"
    $countdownLabel.Text = "Countdown to first alert: $script:thresholdSec sec"
    $form.Text = "Idle Alert (running)"

    $buttonStart.Enabled = $false
    $buttonStop.Enabled = $true

    $timer.Start()
})

# Stop
$buttonStop.Add_Click({
    $timer.Stop()
    $script:firstAlertDone = $false
    $script:lastBeepIdleSec = 0
    $statusLabel.Text = "Status: Stopped"
    $countdownLabel.Text = "Countdown: -"
    $form.Text = "Idle Alert"

    $buttonStart.Enabled = $true
    $buttonStop.Enabled = $false
})

# Tick
$timer.Add_Tick({
    if (-not $timer.Enabled) { return }

    # read current seconds (you can change mins/secs on the fly)
    $tSec = 0; $rSec = 0
    if ([int]::TryParse($textThreshSec.Text, [ref]$tSec) -and $tSec -gt 0) {
        $script:thresholdSec = $tSec
    }
    if ([int]::TryParse($textRepeatSec.Text, [ref]$rSec) -and $rSec -ge 0) {
        $script:repeatSec = $rSec
    }

    $idleMs = [IdleTimeHelper]::GetIdleTimeMs()
    $idleSec = [math]::Round($idleMs / 1000,0)

    if ($idleSec -lt $script:thresholdSec) {
        $script:firstAlertDone = $false
        $script:lastBeepIdleSec = 0
        Update-CountdownLabel -idleSec $idleSec
        return
    }

    if (-not $script:firstAlertDone -and $idleSec -ge $script:thresholdSec) {
        [console]::beep(1000,800)
        $script:firstAlertDone = $true
        $script:lastBeepIdleSec = $idleSec
        $statusLabel.Text = "Status: First alert at $idleSec sec idle"
        Update-CountdownLabel -idleSec $idleSec
        return
    }

    if ($script:firstAlertDone -and $script:repeatSec -gt 0) {
        $sinceLast = $idleSec - $script:lastBeepIdleSec
        if ($sinceLast -ge $script:repeatSec) {
            [console]::beep(1000,800)
            $script:lastBeepIdleSec = $idleSec
            $statusLabel.Text = "Status: Repeated alert at $idleSec sec idle"
        }
    }

    Update-CountdownLabel -idleSec $idleSec
})

$form.Add_FormClosing({ $timer.Stop() })

[void]$form.ShowDialog()
