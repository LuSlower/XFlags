# Check administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Console {
    param ([Switch]$Show, [Switch]$Hide)
    if (-not ("Console.Window" -as [type])) { 
        Add-Type -Name Window -Namespace Console -MemberDefinition '
        [DllImport("Kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
        '
    }

    if ($Show) {
        $consolePtr = [Console.Window]::GetConsoleWindow()
        $null = [Console.Window]::ShowWindow($consolePtr, 5)
    }

    if ($Hide) {
        $consolePtr = [Console.Window]::GetConsoleWindow()
        $null = [Console.Window]::ShowWindow($consolePtr, 0)
    }
}

# Pequeña pero sirve
function Restart-Process {
    param (
        [string]$processName
    )

    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

    if ($process -ne $null) {

        # Obtener la ruta 
        $processPath = (Get-Process -Id $process.Id).Path

        # Detener, Esperar, Iniciar 
        Stop-Process -Id $process.Id -Force
        Start-Sleep -Seconds 1
        Start-Process -FilePath $processPath
    } else {
        Write-Output "Process '$processName' is not running"
    }
}

$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\"

# Establecer ifeo flags
function Set-Ifeo {
    param (
            [string]$process,
            [int]$cpuPriority,
            [int]$ioPriority,
            [int]$pagePriority,
            [int]$useLargePages
    )

    # Crear la clave si no existe
    $processPath = Join-Path -Path $ifeoPath -ChildPath "$process"
    $optionsPath = Join-Path -Path $processPath -ChildPath "PerfOptions"

    if (-not (Test-Path $optionsPath)) {
        New-Item -Path $optionsPath -Force | Out-Null
    }

    # Establecer las global flags
    if ($cpuPriority -ne $null -and $cpuPriority -ne 0) {
        Set-ItemProperty -Path $optionsPath -Name "CpuPriorityClass" -Value $cpuPriority
    } else {
        Remove-ItemProperty -Path $optionsPath -Name "CpuPriorityClass" -ErrorAction SilentlyContinue
    }

    if ($ioPriority -ne $null -and $ioPriority -ne 0) {
        Set-ItemProperty -Path $optionsPath -Name "IoPriority" -Value $ioPriority
    } else {
        Remove-ItemProperty -Path $optionsPath -Name "IoPriority" -ErrorAction SilentlyContinue
    }

    if ($pagePriority -ne $null -and $PagePriority -ne 0) {
        Set-ItemProperty -Path $optionsPath -Name "PagePriority" -Value $pagePriority
    } else {
        Remove-ItemProperty -Path $optionsPath -Name "PagePriority" -ErrorAction SilentlyContinue
    }

    if ($useLargePages -ne $null -and $useLargePages -ne 0) {
        Set-ItemProperty -Path $optionsPath -Name "UseLargePages" -Value $useLargePages
    } else {
        Remove-ItemProperty -Path $optionsPath -Name "UseLargePages" -ErrorAction SilentlyContinue
    }

    $valueNames = @("CpuPriorityClass", "IoPriority", "PagePriority", "UseLargePages")

    # Verificar si la clave esta vacía
    $properties = Get-ItemProperty -Path $optionsPath -ErrorAction Stop
    $hasValue = $false

    foreach ($valueName in $valueNames) {
        if ($properties.PSObject.Properties[$valueName]) {
            $hasValue = $true
            break
        }
    }

    if (-not $hasValue) {
        Remove-Item -Path $processPath -Recurse -Force
    }

}

function Load-Processes {
    $comboBoxProcess.Items.Clear()
    Get-Process | ForEach-Object {
        $comboBoxProcess.Items.Add($_.Name + ".exe ($($_.Id))")
    }
}

function Get-ValueFromText {
    param (
        [string]$inputText
    )
    
    if ($inputText -match '\((\d+)\)') {
        return [int]$matches[1]
    } elseif ($inputText -match 'delete') {
        return $null
    } else {
        return $null  # si no coincide con ningún patrón del match
    }
}

# Ocultar consola, crear form
Console -Hide
[System.Windows.Forms.Application]::EnableVisualStyles();
$form = New-Object System.Windows.Forms.Form
$form.ClientSize = New-Object System.Drawing.Size(250, 200)
$form.Text = "Ifeo-Utility"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F5) {
        Load-Processes
    }
})

# ProcList
$labelProcess = New-Object System.Windows.Forms.Label
$labelProcess.Location = New-Object System.Drawing.Point(10, 15)
$labelProcess.Size = New-Object System.Drawing.Size(50, 13)
$labelProcess.Text = "ProcList:"
$form.Controls.Add($labelProcess)

$comboBoxProcess = New-Object System.Windows.Forms.ComboBox
$comboBoxProcess.Location = New-Object System.Drawing.Point(60, 10)
$comboBoxProcess.Size = New-Object System.Drawing.Size(180, 30)
$comboBoxProcess.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxProcess)

# PriorityClass
$labelCpuPriority = New-Object System.Windows.Forms.Label
$labelCpuPriority.Location = New-Object System.Drawing.Point(20, 50)
$labelCpuPriority.Size = New-Object System.Drawing.Size(80, 23)
$labelCpuPriority.Text = "PriorityClass:"
$form.Controls.Add($labelCpuPriority)

$comboBoxCpuPriority = New-Object System.Windows.Forms.ComboBox
$comboBoxCpuPriority.Location = New-Object System.Drawing.Point(100, 48)
$comboBoxCpuPriority.Size = New-Object System.Drawing.Size(110, 23)
$comboBoxCpuPriority.Items.AddRange(@("Realtime (4)", "High (3)", "Above Normal (6)", "Normal (2)", "Below Normal (5)", "Low (1)", "default (delete)"))
$comboBoxCpuPriority.Text = "default (delete)"
$comboBoxCpuPriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxCpuPriority)

# IoPriority
$labelIoPriority = New-Object System.Windows.Forms.Label
$labelIoPriority.Location = New-Object System.Drawing.Point(40, 80)
$labelIoPriority.Size = New-Object System.Drawing.Size(60, 23)
$labelIoPriority.Text = "IoPriority:"
$form.Controls.Add($labelIoPriority)

$comboBoxIoPriority = New-Object System.Windows.Forms.ComboBox
$comboBoxIoPriority.Location = New-Object System.Drawing.Point(100, 78)
$comboBoxIoPriority.Size = New-Object System.Drawing.Size(110, 23)
$comboBoxIoPriority.Items.AddRange(@("Critical (4)", "High (3)", "Normal (2)", "Low (1)", "default (delete)"))
$comboBoxIoPriority.Text = "default (delete)"
$comboBoxIoPriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxIoPriority)

# MemPriority
$labelMemPriority = New-Object System.Windows.Forms.Label
$labelMemPriority.Location = New-Object System.Drawing.Point(10, 110)
$labelMemPriority.Size = New-Object System.Drawing.Size(85, 23)
$labelMemPriority.Text = "MemoryPriority:"
$form.Controls.Add($labelMemPriority)

$comboBoxPagePriority = New-Object System.Windows.Forms.ComboBox
$comboBoxPagePriority.Location = New-Object System.Drawing.Point(100, 108)
$comboBoxPagePriority.Size = New-Object System.Drawing.Size(110, 23)
$comboBoxPagePriority.Items.AddRange(@("Normal (5)", "Below Normal (4)", "Medium (3)", "Low (2)", "VeryLow (1)", "default (delete)"))
$comboBoxPagePriority.Text = "default (delete)"
$comboBoxPagePriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxPagePriority)

# LargePages
$labelUseLargePages = New-Object System.Windows.Forms.Label
$labelUseLargePages.Location = New-Object System.Drawing.Point(25, 140)
$labelUseLargePages.Size = New-Object System.Drawing.Size(70, 23)
$labelUseLargePages.Text = "LargePages:"
$form.Controls.Add($labelUseLargePages)

$comboBoxUseLargePages = New-Object System.Windows.Forms.ComboBox
$comboBoxUseLargePages.Location = New-Object System.Drawing.Point(100, 138)
$comboBoxUseLargePages.Size = New-Object System.Drawing.Size(110, 23)
$comboBoxUseLargePages.Items.AddRange(@("Enable (1)", "default (delete)"))
$comboBoxUseLargePages.Text = "default (delete)"
$comboBoxUseLargePages.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxUseLargePages)

# Save
$buttonSave = New-Object System.Windows.Forms.Button
$buttonSave.Size = New-Object System.Drawing.Size(80, 20)
$buttonSave.Location = New-Object System.Drawing.Point(95, 170)
$buttonSave.Text = "Save"
$form.Controls.Add($buttonSave)

# aplicar todos los cambios
$buttonSave.Add_Click({
    $process = $comboBoxProcess.SelectedItem
    if ($process.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select a process", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    if ($process -match '^(.+?) \(\d+\)$') {
        $processName = $matches[1]
    }
    
    $cpuPriority = $comboBoxCpuPriority.SelectedItem
    $ioPriority = $comboBoxIoPriority.SelectedItem
    $pagePriority = $comboBoxPagePriority.SelectedItem
    $useLargePages = $comboBoxUseLargePages.SelectedItem

    if (-not $cpuPriority -or -not $ioPriority -or -not $pagePriority -or -not $useLargePages) {
    [System.Windows.Forms.MessageBox]::Show("You must select one option for all priorities", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    return
    }

    # Convertir a valores númericos
    $cpuPriorityValue = Get-ValueFromText -inputText $cpuPriority
    $ioPriorityValue = Get-ValueFromText -inputText $ioPriority
    $pagePriorityValue = Get-ValueFromText -inputText $pagePriority
    $useLargePagesValue = Get-ValueFromText -inputText $useLargePages

    $result = [System.Windows.Forms.MessageBox]::Show("Process: $processName`nPID: $processId`nCPU Priority: $cpuPriority`nIO Priority: $ioPriority`nPage Priority: $pagePriority`nUse Large Pages: $useLargePages`n`nRestart Process?", "Applied settings", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information)
    
    # aplicar configuracion de ifeo
    Set-Ifeo -process $processName -cpuPriority $cpuPriorityValue -ioPriority $ioPriorityValue -pagePriority $pagePriorityValue -useLargePages $useLargePagesValue

    # reiniciar el proceso, opcionalmente
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Restart-Process -processName $ProcessName
    }
})

# cargar procesos al inicio, mostrar form
Load-Processes | Out-Null

[void]$form.ShowDialog()
