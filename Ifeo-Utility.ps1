# Chequear privilegios de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
$delay = 2
if (-not $isAdmin) {
    [System.Windows.Forms.MessageBox]::Show("Ejecute el script como administrador", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    Start-Sleep -Seconds $delay
    Exit
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

# pequeña pero sirve
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

# establecer ifeo flags
function Set-Ifeo {
    param (
            [string]$process,
            [int]$cpuPriority,
            [int]$ioPriority,
            [int]$pagePriority,
            [int]$useLargePages
    )

    # crear la clave si no existe
    $ifeo_key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\"
    $processPath = Join-Path -Path $ifeo_key -ChildPath "$process\PerfOptions"

    if (-not (Test-Path $processPath)) {
        New-Item -Path $processPath -Force | Out-Null
    }

    # establecer las global flags
    if ($cpuPriority -ne $null -and $cpuPriority -ne 0) {
        Set-ItemProperty -Path $processPath -Name "CpuPriorityClass" -Value $cpuPriority
    } else {
        Remove-ItemProperty -Path $processPath -Name "CpuPriorityClass" -ErrorAction SilentlyContinue
    }

    if ($ioPriority -ne $null -and $ioPriority -ne 0) {
        Set-ItemProperty -Path $processPath -Name "IoPriority" -Value $ioPriority
    } else {
        Remove-ItemProperty -Path $processPath -Name "IoPriority" -ErrorAction SilentlyContinue
    }

    if ($pagePriority -ne $null -and $PagePriority -ne 0) {
        Set-ItemProperty -Path $processPath -Name "PagePriority" -Value $pagePriority
    } else {
        Remove-ItemProperty -Path $processPath -Name "PagePriority" -ErrorAction SilentlyContinue
    }

    if ($useLargePages -ne $null -and $useLargePages -ne 0) {
        Set-ItemProperty -Path $processPath -Name "UseLargePages" -Value $useLargePages
    } else {
        Remove-ItemProperty -Path $processPath -Name "UseLargePages" -ErrorAction SilentlyContinue
    }

}

function Load-Processes {
    $comboBoxProcess.Items.Clear()
    Get-Process | ForEach-Object {
        $comboBoxProcess.Items.Add($_.Name + ".exe")
    }
}

# Ocultar consola, crear form
Console -Hide
[System.Windows.Forms.Application]::EnableVisualStyles();
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(250, 240)
$form.Text = "Ifeo-Utility"
$form.MaximizeBox = $false
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

# ComboBox para procesos
$labelProcess = New-Object System.Windows.Forms.Label
$labelProcess.Location = New-Object System.Drawing.Point(10, 15)
$labelProcess.Size = New-Object System.Drawing.Size(70, 13)
$labelProcess.Text = "PROCLIST:"
$form.Controls.Add($labelProcess)

$comboBoxProcess = New-Object System.Windows.Forms.ComboBox
$comboBoxProcess.Location = New-Object System.Drawing.Point(80, 10)
$comboBoxProcess.Size = New-Object System.Drawing.Size(145, 30)
$comboBoxProcess.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxProcess)

# ComboBox para CPU Priority Class
$labelCpuPriority = New-Object System.Windows.Forms.Label
$labelCpuPriority.Location = New-Object System.Drawing.Point(10, 50)
$labelCpuPriority.Size = New-Object System.Drawing.Size(100, 23)
$labelCpuPriority.Text = "CPU Priority:"
$form.Controls.Add($labelCpuPriority)

$comboBoxCpuPriority = New-Object System.Windows.Forms.ComboBox
$comboBoxCpuPriority.Location = New-Object System.Drawing.Point(110, 48)
$comboBoxCpuPriority.Size = New-Object System.Drawing.Size(110, 23)
$comboBoxCpuPriority.Items.AddRange(@("Realtime (4)", "High (3)", "Above Normal (6)", "Normal (2)", "Below Normal (5)", "Low (1)", "default (delete)"))
$comboBoxCpuPriority.Text = "default (delete)"
$comboBoxCpuPriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxCpuPriority)

# ComboBox para IoPriority
$labelIoPriority = New-Object System.Windows.Forms.Label
$labelIoPriority.Location = New-Object System.Drawing.Point(10, 80)
$labelIoPriority.Size = New-Object System.Drawing.Size(100, 23)
$labelIoPriority.Text = "IO Priority:"
$form.Controls.Add($labelIoPriority)

$comboBoxIoPriority = New-Object System.Windows.Forms.ComboBox
$comboBoxIoPriority.Location = New-Object System.Drawing.Point(110, 78)
$comboBoxIoPriority.Size = New-Object System.Drawing.Size(110, 23)
$comboBoxIoPriority.Items.AddRange(@("Critical (4)", "High (3)", "Normal (2)", "Low (1)", "default (delete)"))
$comboBoxIoPriority.Text = "default (delete)"
$comboBoxIoPriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxIoPriority)

# ComboBox para PagePriority
$labelPagePriority = New-Object System.Windows.Forms.Label
$labelPagePriority.Location = New-Object System.Drawing.Point(10, 110)
$labelPagePriority.Size = New-Object System.Drawing.Size(100, 23)
$labelPagePriority.Text = "Page Priority:"
$form.Controls.Add($labelPagePriority)

$comboBoxPagePriority = New-Object System.Windows.Forms.ComboBox
$comboBoxPagePriority.Location = New-Object System.Drawing.Point(110, 108)
$comboBoxPagePriority.Size = New-Object System.Drawing.Size(110, 23)
$comboBoxPagePriority.Items.AddRange(@("Normal (5)", "Below Normal (4)", "Medium (3)", "Low (2)", "VeryLow (1)", "default (delete)"))
$comboBoxPagePriority.Text = "default (delete)"
$comboBoxPagePriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxPagePriority)

$labelUseLargePages = New-Object System.Windows.Forms.Label
$labelUseLargePages.Location = New-Object System.Drawing.Point(10, 140)
$labelUseLargePages.Size = New-Object System.Drawing.Size(100, 23)
$labelUseLargePages.Text = "Use Large Pages:"
$form.Controls.Add($labelUseLargePages)

$comboBoxUseLargePages = New-Object System.Windows.Forms.ComboBox
$comboBoxUseLargePages.Location = New-Object System.Drawing.Point(110, 138)
$comboBoxUseLargePages.Size = New-Object System.Drawing.Size(110, 23)
$comboBoxUseLargePages.Items.AddRange(@("Enable (1)", "default (delete)"))
$comboBoxUseLargePages.Text = "default (delete)"
$comboBoxUseLargePages.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBoxUseLargePages)

$buttonApply = New-Object System.Windows.Forms.Button
$buttonApply.Size = New-Object System.Drawing.Size(75, 23)
$buttonApply.Location = New-Object System.Drawing.Point(25, 170)
$buttonApply.Text = "Apply"
$form.Controls.Add($buttonApply)

$buttonRefresh = New-Object System.Windows.Forms.Button
$buttonRefresh.Size = New-Object System.Drawing.Size(75, 23)
$buttonRefresh.Location = New-Object System.Drawing.Point(130, 170)
$buttonRefresh.Text = "Refresh"
$buttonRefresh.Add_Click({ Load-Processes })
$form.Controls.Add($buttonRefresh)

# aplicar todos los cambios
$buttonApply.Add_Click({
    $ProcessName = $comboBoxProcess.SelectedItem
    if ($ProcessName.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select a process", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    $process = $processName.Replace(".exe", "")
    $processId = (Get-Process -Name $process).Id
    
    $cpuPriority = $comboBoxCpuPriority.SelectedItem
    $ioPriority = $comboBoxIoPriority.SelectedItem
    $pagePriority = $comboBoxPagePriority.SelectedItem
    $useLargePages = $comboBoxUseLargePages.SelectedItem

    if (-not $cpuPriority -or -not $ioPriority -or -not $pagePriority -or -not $useLargePages) {
    [System.Windows.Forms.MessageBox]::Show("You must select one option for all priorities", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    return
    }

        # Convertir a valores númericos
    switch ($cpuPriority) {
        "Realtime (4)"          { $cpuPriorityValue = 4 }
        "High (3)"                 { $cpuPriorityValue = 3 }
        "Above Normal (6)" { $cpuPriorityValue = 6 }
        "Normal (2)"               { $cpuPriorityValue = 2 }
        "Below Normal (5)" { $cpuPriorityValue = 5 }
        "Low (1)"                 { $cpuPriorityValue = 1 }
        "default (delete)"         { $cpuPriorityValue = $null }
    }

    switch ($ioPriority) {
        "Critical (4)"   { $ioPriorityValue = 4 }
        "High (3)"       { $ioPriorityValue = 3 }
        "Normal (2)"     { $ioPriorityValue = 2 }
        "Low (1)"        { $ioPriorityValue = 1 }
        "default (delete)" { $ioPriorityValue = $null }
    }

    switch ($pagePriority) {
        "Normal (5)"     { $pagePriorityValue = 5 }
        "Below Normal (4)" { $pagePriorityValue = 4 }
        "Medium (3)"     { $pagePriorityValue = 3 }
        "Low (2)"        { $pagePriorityValue = 2 }
        "VeryLow (1)"    { $pagePriorityValue = 1 }
        "default (delete)" { $pagePriorityValue = $null }
    }

    switch ($useLargePages) {
        "Enable (1)"     { $useLargePagesValue = 1 }
        "default (delete)" { $useLargePagesValue = $null }
    }
    
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
