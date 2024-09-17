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

# Flags
$flags = @(
    @{Name = "FLG_STOP_ON_EXCEPTION"; Description = "Stop on exception"; Abbreviation = "soe"; Hex = 0x01},
    @{Name = "FLG_SHOW_LDR_SNAPS"; Description = "Show loader snaps"; Abbreviation = "sls"; Hex = 0x02},
    @{Name = "FLG_DEBUG_INITIAL_COMMAND"; Description = "Debug initial command"; Abbreviation = "dic"; Hex = 0x04},
    @{Name = "FLG_HEAP_ENABLE_FREE_CHECK"; Description = "Enable heap free checking"; Abbreviation = "hfc"; Hex = 0x20},
    @{Name = "FLG_HEAP_ENABLE_TAIL_CHECK"; Description = "Enable heap tail checking"; Abbreviation = "htc"; Hex = 0x10},
    @{Name = "FLG_HEAP_VALIDATE_ALL"; Description = "Enable heap validation on call"; Abbreviation = "hvc"; Hex = 0x80},
    @{Name = "FLG_HEAP_VALIDATE_PARAMETERS"; Description = "Enable heap parameter checking"; Abbreviation = "hpc"; Hex = 0x40},
    @{Name = "FLG_HEAP_ENABLE_TAGGING"; Description = "Enable heap tagging"; Abbreviation = "htg"; Hex = 0x0800},
    @{Name = "FLG_MAINTAIN_OBJECT_TYPELIST"; Description = "Maintain a list of objects for each type"; Abbreviation = "otl"; Hex = 0x4000},
    @{Name = "FLG_MONITOR_SILENT_PROCESS_EXIT"; Description = "Enable silent process exit monitoring"; Abbreviation = "mspe"; Hex = 0x200},
    @{Name = "FLG_DISABLE_STACK_EXTENSION"; Description = "Disable stack extension"; Abbreviation = "dse"; Hex = 0x010000},
    @{Name = "FLG_ENABLE_CSRDEBUG"; Description = "Enable debugging of Win32 subsystem"; Abbreviation = "d32"; Hex = 0x020000},
    @{Name = "FLG_ENABLE_EXCEPTION_LOGGING"; Description = "Enable exception logging"; Abbreviation = "eel"; Hex = 0x800000},
    @{Name = "FLG_ENABLE_KDEBUG_SYMBOL_LOAD"; Description = "Enable loading of kernel debugger symbols"; Abbreviation = "ksl"; Hex = 0x040000},
    @{Name = "FLG_HEAP_ENABLE_TAG_BY_DLL"; Description = "Enable heap tagging by DLL"; Abbreviation = "htd"; Hex = 0x8000},
    @{Name = "FLG_HEAP_PAGE_ALLOCS"; Description = "Enable page heap"; Abbreviation = "hpa"; Hex = 0x02000000},
    @{Name = "FLG_HEAP_DISABLE_COALESCING"; Description = "Disable heap coalesce on free"; Abbreviation = "dhc"; Hex = 0x00200000},
    @{Name = "FLG_DISABLE_PAGE_KERNEL_STACKS"; Description = "Disable paging of kernel stacks"; Abbreviation = "dps"; Hex = 0x080000},
    @{Name = "FLG_ENABLE_CLOSE_EXCEPTIONS"; Description = "Enable close exception"; Abbreviation = "ece"; Hex = 0x400000},
    @{Name = "FLG_ENABLE_HANDLE_TYPE_TAGGING"; Description = "Enable object handle type tagging"; Abbreviation = "eot"; Hex = 0x01000000},
    @{Name = "FLG_ENABLE_HANDLE_EXCEPTIONS"; Description = "Enable bad handles detection"; Abbreviation = "bhd"; Hex = 0x40000000},
    @{Name = "FLG_DISABLE_PROTDLLS"; Description = "Disable protected DLL verification"; Abbreviation = "dpd"; Hex = 0x80000000},
    @{Name = "FLG_DEBUG_INITIAL_COMMAND_EX"; Description = "Debug WinLogon"; Abbreviation = "dwl"; Hex = 0x04000000},
    @{Name = "FLG_CRITSEC_EVENT_CREATION"; Description = "Early critical section event creation"; Abbreviation = "cse"; Hex = 0x10000000},
    @{Name = "FLG_STOP_ON_UNHANDLED_EXCEPTION"; Description = "Stop on unhandled user-mode exception"; Abbreviation = "sue"; Hex = 0x20000000},
    @{Name = "FLG_ENABLE_SYSTEM_CRIT_BREAKS"; Description = "Enable system critical breaks"; Abbreviation = "scb"; Hex = 0x100000}
)

# MitigationOptions
$mitigationOptions = @(
    @{Name = "FLG_ASLR"; Description = "Address Space Layout Randomization"; Abbreviation = "aslr"; Flags = @{AlwaysOn = 0x100; AlwaysOff = 0x200}},
    @{Name = "FLG_HeapTermination"; Description = "Heap Termination on Corruption"; Abbreviation = "heapt"; Flags = @{AlwaysOn = 0x1000; AlwaysOff = 0x2000}},
    @{Name = "FLG_BottomUpASLR"; Description = "Bottom-Up ASLR"; Abbreviation = "buaslr"; Flags = @{AlwaysOn = 0x10000; AlwaysOff = 0x20000}},
    @{Name = "FLG_HEASLR"; Description = "High Entropy ASLR"; Abbreviation = "heaslr"; Flags = @{AlwaysOn = 0x100000; AlwaysOff = 0x200000}},
    @{Name = "FLG_SHC"; Description = "Strict Handle Checks"; Abbreviation = "shc"; Flags = @{AlwaysOn = 0x1000000; AlwaysOff = 0x2000000}},
    @{Name = "FLG_DisableWin32KCalls"; Description = "Disable Win32K Calls"; Abbreviation = "dis-win32k"; Flags = @{AlwaysOn = 0x10000000; AlwaysOff = 0x20000000}},
    @{Name = "FLG_DisableExtensionPoint"; Description = "Disable Extension Point"; Abbreviation = "dis-extpoint"; Flags = @{AlwaysOn = 0x100000000; AlwaysOff = 0x200000000}},
    @{Name = "FLG_DisableDynamicCode"; Description = "Disable Dynamic Code"; Abbreviation = "dis-dyncode"; Flags = @{AlwaysOn = 0x1000000000; AlwaysOff = 0x2000000000}},
    @{Name = "FLG_CFG"; Description = "Control Flow Guard"; Abbreviation = "cfg"; Flags = @{AlwaysOn = 0x10000000000; AlwaysOff = 0x20000000000}},
    @{Name = "FLG_BlockNonMicrosoftBinaries"; Description = "Block Non-Microsoft Binaries"; Abbreviation = "block-non-ms"; Flags = @{AlwaysOn = 0x100000000000; AlwaysOff = 0x200000000000}},
    @{Name = "FLG_BlockNonSystemFonts"; Description = "Block Non-System Fonts"; Abbreviation = "block-non-sysf"; Flags = @{AlwaysOn = 0x1000000000000; AlwaysOff = 0x2000000000000}},
    @{Name = "FLG_DisableRemoteLoads"; Description = "Disable Remote Loads"; Abbreviation = "dis-remloads"; Flags = @{AlwaysOn = 0x10000000000000; AlwaysOff = 0x20000000000000}},
    @{Name = "FLG_DisableLowIntegrityLoads"; Description = "Disable Low Integrity Loads"; Abbreviation = "dis-lowintl"; Flags = @{AlwaysOn = 0x100000000000000; AlwaysOff = 0x200000000000000}},
    @{Name = "FLG_PreferSystemImages"; Description = "Prefer System Images"; Abbreviation = "pref-sysimg"; Flags = @{AlwaysOn = 0x1000000000000000; AlwaysOff = 0x2000000000000000}}
)

$otherMitigationOptions = @(
    @{Name = "FLG_DEP"; Description = "Data Execution Prevention"; Abbreviation = "dep"; Hex = 0x1; Flags = @{AlwaysOn = 0x1}},
    @{Name = "FLG_ATLThunk"; Description = "ATL Thunk Emulation"; Abbreviation = "atl"; Hex = 0x2; Flags = @{AlwaysOn = 0x2}},
    @{Name = "FLG_SEHOP"; Description = "Structured Exception Handler Overwrite Protection"; Abbreviation = "sehop"; Hex = 0x4; Flags = @{AlwaysOn = 0x4}}
)

# Pequeña pero sirve
function Restart-Process {
    param (
        [string]$processName
    )

    $process = Get-Process -Name $processName -ErrorAction Stop

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
            [int]$useLargePages,
            [string]$debugger,
            [int]$mitigationOp,
            [int]$globalFlag
    )

    # Crear la clave si no existe
    $default = Join-Path -Path $ifeoPath -ChildPath "$process"
    $options = Join-Path -Path $default -ChildPath "PerfOptions"

    if (-not (Test-Path $options)) {
        New-Item -Path $options -Force | Out-Null
    }

    # Establecer las global flags
    if ($cpuPriority -ne $null -and $cpuPriority -ne 0) {
        Set-ItemProperty -Path $options -Name "CpuPriorityClass" -Value $cpuPriority
    } else {
        Remove-ItemProperty -Path $options -Name "CpuPriorityClass" -ErrorAction SilentlyContinue
    }

    if ($ioPriority -ne $null -and $ioPriority -ne 0) {
        Set-ItemProperty -Path $options -Name "IoPriority" -Value $ioPriority
    } else {
        Remove-ItemProperty -Path $options -Name "IoPriority" -ErrorAction SilentlyContinue
    }

    if ($pagePriority -ne $null -and $PagePriority -ne 0) {
        Set-ItemProperty -Path $options -Name "PagePriority" -Value $pagePriority
    } else {
        Remove-ItemProperty -Path $options -Name "PagePriority" -ErrorAction SilentlyContinue
    }

    if ($useLargePages -ne $null -and $useLargePages -ne 0) {
        Set-ItemProperty -Path $default -Name "UseLargePages" -Value $useLargePages
    } else {
        Remove-ItemProperty -Path $default -Name "UseLargePages" -ErrorAction SilentlyContinue
    }

    if (![string]::IsNullOrEmpty($debugger)) {
        Set-ItemProperty -Path $default -Name "Debugger" -Value $debugger
    } else {
        Remove-ItemProperty -Path $default -Name "Debugger" -ErrorAction SilentlyContinue
    }

    if ($mitigationOp -ne $null -and $mitigationOp -ne 0) {
        Set-ItemProperty -Path $default -Name "MitigationOptions" -Value $mitigationOp
    } else {
        Remove-ItemProperty -Path $default -Name "MitigationOptions" -ErrorAction SilentlyContinue
    }

    if ($globalFlag -ne $null -and $globalFlag -ne 0) {
        Set-ItemProperty -Path $default -Name "GlobalFlag" -Value $globalFlag
    } else {
        Remove-ItemProperty -Path $default -Name "GlobalFlag" -ErrorAction SilentlyContinue
    }

    $valueNames = @("CpuPriorityClass", "IoPriority", "PagePriority")

    # Verificar si la clave esta vacía
    $properties = Get-ItemProperty -Path $options -ErrorAction Stop
    $hasValue = $false

    foreach ($valueName in $valueNames) {
        if ($properties.PSObject.Properties[$valueName]) {
            $hasValue = $true
            break
        }
    }

    if (-not $hasValue) {
        Remove-Item -Path $options -Recurse -Force
    }

}

function Get-Ifeo {
    param (
        [string]$process
    )

    # Definir rutas de registro
    $defaultPath = Join-Path -Path $ifeoPath -ChildPath "$process"
    $optionsPath = Join-Path -Path $defaultPath -ChildPath "PerfOptions"

    # Verificar si la clave existe
    if (-not (Test-Path $defaultPath)) {
        return
    }

    $result = @{
        CpuPriority = $null
        IoPriority = $null
        PagePriority = $null
        UseLargePages = $null
        GlobalFlag = $null
        MitigationOptions = $null
        Debugger = $null
    }

    $default = Get-ItemProperty -Path $defaultPath -ErrorAction Stop

    if ($default.PSObject.Properties["UseLargePages"]) {
        $result.UseLargePages = $default.UseLargePages
    }

    if ($default.PSObject.Properties["GlobalFlag"]) {
        $result.GlobalFlag = $default.GlobalFlag
    }

    if ($default.PSObject.Properties["MitigationOptions"]) {
        $result.MitigationOptions = $default.MitigationOptions
    }

    if ($default.PSObject.Properties["Debugger"]) {
        $result.Debugger = $default.Debugger
    }

    # Verificar si la clave existe
    if (-not (Test-Path $optionsPath)) {
        return $result
    }

    $options = Get-ItemProperty -Path $optionsPath -ErrorAction Stop

    if ($options.PSObject.Properties["CpuPriorityClass"]) {
        $result.CpuPriority = $options.CpuPriorityClass
    }

    if ($options.PSObject.Properties["IoPriority"]) {
        $result.IoPriority = $options.IoPriority
    }

    if ($options.PSObject.Properties["PagePriority"]) {
        $result.PagePriority = $options.PagePriority
    }

    return $result
}

function Load-Processes-Ifeo {
    $listBoxProcesses.Items.Clear()

    if ($rdbtnProcess.Checked) {
        # Cargar procesos en ejecución
        Get-Process | ForEach-Object {
            $listBoxProcesses.Items.Add($_.Name + ".exe")
        }
    } elseif ($rdbtnConfig.Checked) {
        # Cargar procesos desde el registro
        $keys = Get-ChildItem -Path $ifeoPath

        foreach ($key in $keys) {
            $processName = $key.Name
            if ($processName -match '^[^\\]+$') {
                $processName = $processName + ".exe"
            } else {
                # Eliminar parte de la ruta del registro (en este caso, solo conservar el nombre del proceso)
                $processName = [System.IO.Path]::GetFileName($processName)
            }
            $listBoxProcesses.Items.Add($processName)
        }
    }
}

function Reset-Checkboxes {
    param (
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Control]$parentControl
    )

    # Recorrer todos los controles del contenedor padre
    foreach ($control in $parentControl.Controls) {
        # Verificar si el control es un CheckBox
        if ($control -is [System.Windows.Forms.CheckBox]) {
            $checkBox = [System.Windows.Forms.CheckBox]$control
            $checkBox.CheckState = [System.Windows.Forms.CheckState]::Unchecked
        }
    }
}

function Set-ValueFromNumber {
    param (
        [System.Windows.Forms.ComboBox]$comboBox,
        [int]$number
    )
    
    if ($number -eq $null) {
        # Seleccionar "default (delete)" si el número es $null
        $defaultItem = $comboBox.Items | Where-Object { $_ -match "default \(delete\)" }
        if ($defaultItem) {
            $comboBox.SelectedItem = $defaultItem
        } else {
            $comboBox.SelectedIndex = -1
        }
        return
    }
    
    foreach ($item in $comboBox.Items) {
        if ($item -match ".*\($number\).*") {
            $comboBox.SelectedItem = $item
            return
        }
    }
    
    # Si no se encuentra, seleccionar "default (delete)"
    $defaultItem = $comboBox.Items | Where-Object { $_ -match "default \(delete\)" }
    if ($defaultItem) {
        $comboBox.SelectedItem = $defaultItem
    } else {
        $comboBox.SelectedIndex = -1
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

# MitigationOptionsMask
$global:bitmaskMit = 0

function Update-MitigationMask {
    $global:bitmaskMit = 0

    # ThreeState
    foreach ($entry in $checkboxesMit) {
        $checkbox = $entry.CheckBox
        $option = $entry.Option
        if ($checkbox.CheckState -eq [System.Windows.Forms.CheckState]::Checked) {
            $global:bitmaskMit = $global:bitmaskMit -bor $option.Flags.AlwaysOn
        } elseif ($checkbox.CheckState -eq [System.Windows.Forms.CheckState]::Indeterminate) {
            $global:bitmaskMit = $global:bitmaskMit -bor $option.Flags.AlwaysOff
        }
    }

    # TwoState
    foreach ($option in $otherMitigationOptions) {
        $checkbox = $tabMit.Controls.Find($option.Abbreviation, $true)[0]
        if ($checkbox.CheckState -eq [System.Windows.Forms.CheckState]::Checked) {
            $global:bitmaskMit = $global:bitmaskMit -bor $option.Hex
        }
    }

    $labelMit.Text = "BitMask: 0x" + "{0:X}" -f $global:bitmaskMit
}

function Load-MitigationMask {
    param (
        [Parameter(Mandatory=$true)]
        [UInt64]$bitmask
    )

    foreach ($entry in $checkboxesMit) {
        $checkbox = $entry.CheckBox
        $option = $entry.Option

        if ($bitmask -band $option.Flags.AlwaysOn) {
            $checkbox.CheckState = [System.Windows.Forms.CheckState]::Checked
        } elseif ($bitmask -band $option.Flags.AlwaysOff) {
            $checkbox.CheckState = [System.Windows.Forms.CheckState]::Indeterminate
        } else {
            $checkbox.CheckState = [System.Windows.Forms.CheckState]::Unchecked
        }
    }
}

function Load-OtherMitigationOptions {
    param (
        [Parameter(Mandatory=$true)]
        [UInt64]$bitmask
    )

    foreach ($option in $otherMitigationOptions) {
        $controls = $tabMit.Controls.Find($option.Abbreviation, $true)
        if ($controls.Count -gt 0) {
            $checkbox = $controls[0]

            # Verificar que el control es un CheckBox
            if ($bitmask -band $option.Hex) {
                $checkbox.CheckState = [System.Windows.Forms.CheckState]::Checked
            } else {
                $checkbox.CheckState = [System.Windows.Forms.CheckState]::Unchecked
            }
        }
    }
}


#GFLagsMask
$global:bitmaskFlags = 0

function Update-FlagsMask {
    $global:bitmaskFlags = 0
    foreach ($entry in $checkboxesFlags) {
        $checkbox = $entry.CheckBox
        $option = $entry.Option
        if ($checkbox.CheckState -eq [System.Windows.Forms.CheckState]::Checked) {
            $global:bitmaskFlags = $global:bitmaskFlags -bor $option.Hex
        }
    }
    $labelGFlags.Text = "BitMask: 0x" + "{0:X}" -f $global:bitmaskFlags
}

function Load-FlagsMask {
    param (
        [Parameter(Mandatory=$true)]
        [UInt32]$bitmask
    )

    foreach ($entry in $checkboxesFlags) {
        $checkbox = $entry.CheckBox
        $option = $entry.Option
        
        if ($bitmask -band $option.Hex) {
            $checkbox.CheckState = [System.Windows.Forms.CheckState]::Checked
        } else {
            $checkbox.CheckState = [System.Windows.Forms.CheckState]::Unchecked
        }
    }
}

# Ocultar consola, crear form
Console -Hide
[System.Windows.Forms.Application]::EnableVisualStyles();
$form = New-Object System.Windows.Forms.Form
$form.ClientSize = New-Object System.Drawing.Size(360, 310)
$form.Text = "XFlags"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.KeyPreview = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(44, 44, 44)
$form.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F5) {
        Load-Processes-Ifeo
    }
})

$listBoxProcesses = New-Object System.Windows.Forms.ListBox
$listBoxProcesses.Location = New-Object System.Drawing.Point(10, 28)
$listBoxProcesses.Size = New-Object System.Drawing.Size(150, 250)
$listBoxProcesses.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$listBoxProcesses.BackColor = [System.Drawing.Color]::FromArgb(44, 44, 44)
$listBoxProcesses.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($listBoxProcesses)
$listBoxProcesses.add_SelectedIndexChanged({
    # Obtener el proceso seleccionado
    $selectedProcess = $listBoxProcesses.SelectedItem

    # Obtener la configuración
    $config = Get-Ifeo -process $selectedProcess

    if ($config) {
        # PerfOptions
        $cpuPriority = if ($null -ne $config.CpuPriority) { $config.CpuPriority } else { 0 }
        $ioPriority = if ($null -ne $config.IoPriority) { $config.IoPriority } else { 0 }
        $pagePriority = if ($null -ne $config.PagePriority) { $config.PagePriority } else { 0 }

        Set-ValueFromNumber -comboBox $comboBoxCpuPriority -number $cpuPriority
        Set-ValueFromNumber -comboBox $comboBoxIoPriority -number $ioPriority
        Set-ValueFromNumber -comboBox $comboBoxPagePriority -number $pagePriority

        # Large Pages
        if ($null -ne $config.UseLargePages -and $config.UseLargePages -ge 1) {
            $chkbLargePages.CheckState = [System.Windows.Forms.CheckState]::Checked
        } else {
            $chkbLargePages.CheckState = [System.Windows.Forms.CheckState]::Unchecked
        }

        # Debugger
        $txtDbgr.Text = if ($null -ne $config.Debugger) { $config.Debugger } else { "" }

        # Mitigation
        $mitigationOptions = if ($null -ne $config.MitigationOptions) { $config.MitigationOptions } else { 0 }
        $labelMit.Text = "BitMask: 0x{0:X}" -f $mitigationOptions + " (Registry)"
        Load-MitigationMask -bitmask $mitigationOptions
        Load-OtherMitigationOptions -bitmask $mitigationOptions

        # Global Flags
        $globalFlags = if ($null -ne $config.GlobalFlag) { $config.GlobalFlag } else { 0 }
        $labelGFlags.Text = "BitMask: 0x{0:X}" -f $globalFlags + " (Registry)"
        Load-FlagsMask -bitmask $globalFlags
    }
})

# Process
$rdbtnProcess = New-Object System.Windows.Forms.RadioButton
$rdbtnProcess.Text = "Process"
$rdbtnProcess.Size = New-Object System.Drawing.Size(70, 20)
$rdbtnProcess.Location = New-Object System.Drawing.Point(10, 280)
$rdbtnProcess.Checked = $true
$rdbtnProcess.UseVisualStyleBackColor = $false
$rdbtnProcess.BackColor = [System.Drawing.Color]::Transparent
$rdbtnProcess.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($rdbtnProcess)
$rdbtnProcess.add_CheckedChanged({
    Load-Processes-Ifeo
})

# Config
$rdbtnConfig = New-Object System.Windows.Forms.RadioButton
$rdbtnConfig.Text = "Config"
$rdbtnConfig.Size = New-Object System.Drawing.Size(60, 20)
$rdbtnConfig.Location = New-Object System.Drawing.Point(80, 280)
$rdbtnConfig.UseVisualStyleBackColor = $false
$rdbtnConfig.BackColor = [System.Drawing.Color]::Transparent
$rdbtnConfig.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($rdbtnConfig)
$rdbtnConfig.add_CheckedChanged({
    Load-Processes-Ifeo
})

Load-Processes-Ifeo | Out-Null

# TabControl
$tab = New-Object System.Windows.Forms.TabControl
$tab.Dock = [System.Windows.Forms.DockStyle]::Fill
$tab.Add_SelectedIndexChanged({
    if ($tab.SelectedIndex -eq 0) {
        $form.ClientSize = New-Object System.Drawing.Size(360, 310)
    } elseif ($tab.SelectedIndex -ge 1) {
        $form.ClientSize = New-Object System.Drawing.Size(430, 310)
    }
})

# Ifeo
$tabIfeo = New-Object System.Windows.Forms.TabPage
$tabIfeo.Text = "General"
$tabIfeo.BackColor = [System.Drawing.Color]::FromArgb(44, 44, 44)

# PriorityClass
$labelCpuPriority = New-Object System.Windows.Forms.Label
$labelCpuPriority.Location = New-Object System.Drawing.Point(210, 20)
$labelCpuPriority.Size = New-Object System.Drawing.Size(80, 13)
$labelCpuPriority.Text = "PriorityClass:"
$labelCpuPriority.ForeColor = [System.Drawing.Color]::White
$labelCpuPriority.BackColor = [System.Drawing.Color]::Transparent
$tabIfeo.Controls.Add($labelCpuPriority)

$comboBoxCpuPriority = New-Object System.Windows.Forms.ComboBox
$comboBoxCpuPriority.Location = New-Object System.Drawing.Point(210, 38)
$comboBoxCpuPriority.Size = New-Object System.Drawing.Size(95, 23)
$comboBoxCpuPriority.Items.AddRange(@("Realtime (4)", "High (3)", "Above Normal (6)", "Normal (2)", "Below Normal (5)", "Low (1)", "default (delete)"))
$comboBoxCpuPriority.Text = "default (delete)"
$comboBoxCpuPriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboBoxCpuPriority.ForeColor = [System.Drawing.Color]::White
$comboBoxCpuPriority.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$tabIfeo.Controls.Add($comboBoxCpuPriority)

# IoPriority
$labelIoPriority = New-Object System.Windows.Forms.Label
$labelIoPriority.Location = New-Object System.Drawing.Point(210, 70)
$labelIoPriority.Size = New-Object System.Drawing.Size(60, 13)
$labelIoPriority.Text = "IoPriority:"
$labelIoPriority.ForeColor = [System.Drawing.Color]::White
$labelIoPriority.BackColor = [System.Drawing.Color]::Transparent
$tabIfeo.Controls.Add($labelIoPriority)

$comboBoxIoPriority = New-Object System.Windows.Forms.ComboBox
$comboBoxIoPriority.Location = New-Object System.Drawing.Point(210, 88)
$comboBoxIoPriority.Size = New-Object System.Drawing.Size(95, 23)
$comboBoxIoPriority.Items.AddRange(@("Critical (4)", "High (3)", "Normal (2)", "Low (1)", "default (delete)"))
$comboBoxIoPriority.Text = "default (delete)"
$comboBoxIoPriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboBoxIoPriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboBoxIoPriority.ForeColor = [System.Drawing.Color]::White
$comboBoxIoPriority.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$tabIfeo.Controls.Add($comboBoxIoPriority)

# MemPriority
$labelMemPriority = New-Object System.Windows.Forms.Label
$labelMemPriority.Location = New-Object System.Drawing.Point(210, 120)
$labelMemPriority.Size = New-Object System.Drawing.Size(85, 13)
$labelMemPriority.Text = "PagePriority:"
$labelMemPriority.ForeColor = [System.Drawing.Color]::White
$labelMemPriority.BackColor = [System.Drawing.Color]::Transparent
$tabIfeo.Controls.Add($labelMemPriority)

$comboBoxPagePriority = New-Object System.Windows.Forms.ComboBox
$comboBoxPagePriority.Location = New-Object System.Drawing.Point(210, 138)
$comboBoxPagePriority.Size = New-Object System.Drawing.Size(95, 23)
$comboBoxPagePriority.Items.AddRange(@("Normal (5)", "Below Normal (4)", "Medium (3)", "Low (2)", "VeryLow (1)", "default (delete)"))
$comboBoxPagePriority.Text = "default (delete)"
$comboBoxPagePriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboBoxPagePriority.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboBoxPagePriority.ForeColor = [System.Drawing.Color]::White
$comboBoxPagePriority.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$tabIfeo.Controls.Add($comboBoxPagePriority)

# LargePages
$chkbLargePages = New-Object System.Windows.Forms.CheckBox
$chkbLargePages.Location = New-Object System.Drawing.Point(210, 172)
$chkbLargePages.Size = New-Object System.Drawing.Size(105, 20)
$chkbLargePages.Text = "UseLargePages"
$chkbLargePages.ForeColor = [System.Drawing.Color]::White
$chkbLargePages.BackColor = [System.Drawing.Color]::Transparent
$tabIfeo.Controls.Add($chkbLargePages)
$tooltip = New-Object System.Windows.Forms.ToolTip
$tooltip.SetToolTip($chkbLargePages, "Enable Large Pages if possible")

# Dbg
$labelDbgr = New-Object System.Windows.Forms.Label
$labelDbgr.Location = New-Object System.Drawing.Point(170, 210)
$labelDbgr.Size = New-Object System.Drawing.Size(70, 13)
$labelDbgr.Text = "Debugger:"
$labelDbgr.ForeColor = [System.Drawing.Color]::White
$labelDbgr.BackColor = [System.Drawing.Color]::Transparent
$tabIfeo.Controls.Add($labelDbgr)

$txtDbgr = New-Object System.Windows.Forms.TextBox
$txtDbgr.Location = New-Object System.Drawing.Point(170, 228)
$txtDbgr.Size = New-Object System.Drawing.Size(150, 20)
$txtDbgr.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtDbgr.BackColor = [System.Drawing.Color]::FromArgb(44, 44, 44)
$txtDbgr.ForeColor = [System.Drawing.Color]::White
$tabIfeo.Controls.Add($txtDbgr)

$btnSearchDbg = New-Object System.Windows.Forms.Button
$btnSearchDbg.Location = New-Object System.Drawing.Point(325, 228)
$btnSearchDbg.Size = New-Object System.Drawing.Size(25, 20)
$btnSearchDbg.Text = "..."
$btnSearchDbg.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSearchDbg.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$btnSearchDbg.ForeColor = [System.Drawing.Color]::White
$btnSearchDbg.FlatAppearance.BorderSize = 0
$tabIfeo.Controls.Add($btnSearchDbg)
$btnSearchDbg.Add_Click({
    # Crear el OpenFileDialog
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Executables (*.exe)|*.exe|All files (*.*)|*.*"
    $openFileDialog.Title = "Select Debugger"
    
    # Mostrar el diálogo de selección de archivos
    $result = $openFileDialog.ShowDialog()

    # Verificar si el usuario seleccionó un archivo y presionó OK
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Obtener la ruta del archivo seleccionado
        $selectedFile = $openFileDialog.FileName

        # Establecer la ruta del archivo en el TextBox
        $txtDbgr.Text = $selectedFile
    }
})

# SaveConfig
$buttonSave = New-Object System.Windows.Forms.Button
$buttonSave.Location = New-Object System.Drawing.Point(230, 260)
$buttonSave.Size = New-Object System.Drawing.Size(50, 20)
$buttonSave.Text = "Save"
$buttonSave.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonSave.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$buttonSave.ForeColor = [System.Drawing.Color]::White
$buttonSave.FlatAppearance.BorderSize = 0
$tabIfeo.Controls.Add($buttonSave)

# aplicar todos los cambios
$buttonSave.Add_Click({
    $process = $listBoxProcesses.SelectedItem
    if ($process.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select a process", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $cpuPriority = $comboBoxCpuPriority.SelectedItem
    $ioPriority = $comboBoxIoPriority.SelectedItem
    $pagePriority = $comboBoxPagePriority.SelectedItem
    $useLargePages = if ($chkbLargePages.Checked) {"Enabled (1)"} else {"default (delete)"}
    $debugger = $txtDbgr.Text

    if (-not $cpuPriority -or -not $ioPriority -or -not $pagePriority) {
        [System.Windows.Forms.MessageBox]::Show("You must select one option for all priorities", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }

    # Convertir a valores númericos
    $cpuPriorityValue = Get-ValueFromText -inputText $cpuPriority
    $ioPriorityValue = Get-ValueFromText -inputText $ioPriority
    $pagePriorityValue = Get-ValueFromText -inputText $pagePriority
    
    # aplicar configuracion de ifeo
    Set-Ifeo -process $process -cpuPriority $cpuPriorityValue -ioPriority $ioPriorityValue -pagePriority $pagePriorityValue -useLargePages $useLargePagesValue -debugger $debugger -mitigationOp $bitmaskMit -globalFlag $bitmaskFlags
    
    $processName = $process.Replace(".exe", "")
    $existProcess = Get-Process -Name $processName -ErrorAction Stop

    if ($existProcess) {
        $result = [System.Windows.Forms.MessageBox]::Show("Restart Process?", "Applied settings", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information)
    
        # reiniciar el proceso, opcionalmente
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            Restart-Process -processName $processName
        }
    }
})

### MitigationOptions
$tabMit = New-Object System.Windows.Forms.TabPage
$tabMit.Text = "MitigationOptions"
$tabMit.BackColor = [System.Drawing.Color]::FromArgb(44, 44, 44)

# MitigationBitmask
$labelMit = New-Object System.Windows.Forms.Label
$labelMit.Location = New-Object System.Drawing.Point(180, 10)
$labelMit.Size = New-Object System.Drawing.Size(250, 13)
$labelMit.Text = "BitMask: 0x0"
$labelMit.ForeColor = [System.Drawing.Color]::White
$labelMit.BackColor = [System.Drawing.Color]::Transparent
$tabMit.Controls.Add($labelMit)

# Configuración de posición inicial y dimensiones del área visible
$startX = 180
$startY = 40
$currentX = $startX
$currentY = $startY
$columnWidth = 120  # Ancho de la columna
$rowHeight = 25     # Espacio entre filas
$maxCheckboxesPerColumn = 7  # Número máximo de CheckBoxes por columna
$checkboxCount = 0  # Contador de CheckBoxes en la columna actual

$checkboxesMit = @()

foreach ($option in $mitigationOptions) {
    # Crear CheckBox
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $option.Abbreviation
    $checkbox.ThreeState = $true
    $checkbox.Location = New-Object System.Drawing.Point($currentX, $currentY)
    $checkbox.Size = New-Object System.Drawing.Size(100, 20)  # Ajustar el tamaño del CheckBox
    $checkbox.ForeColor = [System.Drawing.Color]::White
    $checkbox.BackColor = [System.Drawing.Color]::Transparent
    $tabMit.Controls.Add($checkbox)
    $checkbox.Add_Click({
        switch ($checkbox.CheckState) {
            [System.Windows.Forms.CheckState]::Unchecked {
                $checkbox.CheckState = [System.Windows.Forms.CheckState]::Checked
                break
            }
            [System.Windows.Forms.CheckState]::Checked {
                $checkbox.CheckState = [System.Windows.Forms.CheckState]::Indeterminate
                break
            }
            [System.Windows.Forms.CheckState]::Indeterminate {
                $checkbox.CheckState = [System.Windows.Forms.CheckState]::Unchecked
                break
            }
        }
        Update-MitigationMask
    })

    $checkboxesMit += [PSCustomObject]@{ CheckBox = $checkbox; Option = $option }

    # Añadir SymbolicName al ToolTip
    $tooltip.SetToolTip($checkbox, $option.Description)

    # Ajustar la posición para el próximo CheckBox
    $checkboxCount++
    $currentY += $rowHeight

    # Si se ha alcanzado el número máximo de CheckBoxes en la columna, mover a la siguiente columna
    if ($checkboxCount -ge $maxCheckboxesPerColumn) {
        $checkboxCount = 0
        $currentY = $startY
        $currentX += $columnWidth
    }
}

# DEP
$startX = 180
$currentX = $startX

foreach ($option in $otherMitigationOptions){
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $option.Abbreviation
    $width = ($option.Name).Length + 60
    $checkbox.Location = New-Object System.Drawing.Point($currentX, 225)
    $checkbox.Size = New-Object System.Drawing.Size($width, 20)  # Ajustar el tamaño del CheckBox
    $checkbox.ForeColor = [System.Drawing.Color]::White
    $checkbox.BackColor = [System.Drawing.Color]::Transparent
    $tabMit.Controls.Add($checkbox)
    $checkbox.Add_Click({
        Update-MitigationMask
    })

    $checkboxesMit += [PSCustomObject]@{ CheckBox = $checkbox; Option = $option }

    # ToolTip
    $tooltip.SetToolTip($checkbox, $option.Description)

    $currentX+=85
}

# ResetMask
$btnResetMit = New-Object System.Windows.Forms.Button
$btnResetMit.Location = New-Object System.Drawing.Point(255, 255)
$btnResetMit.Size = New-Object System.Drawing.Size(90, 20)
$btnResetMit.Text = "ResetMask"
$btnResetMit.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnResetMit.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$btnResetMit.ForeColor = [System.Drawing.Color]::White
$btnResetMit.FlatAppearance.BorderSize = 0
$tabMit.Controls.Add($btnResetMit)
$btnResetMit.Add_Click({
    Reset-Checkboxes -parentControl $tabMit

    $global:bitmaskMit = 0
    $labelMit.Text = "BitMask: 0x{0:X}" -f $global:bitmaskMit
})

### GFlags
$tabGFlags = New-Object System.Windows.Forms.TabPage
$tabGFlags.Text = "Gflags"
$tabGFlags.BackColor = [System.Drawing.Color]::FromArgb(44, 44, 44)

# GFlagBitmask
$labelGFlags = New-Object System.Windows.Forms.Label
$labelGFlags.Location = New-Object System.Drawing.Point(180, 10)
$labelGFlags.Size = New-Object System.Drawing.Size(200, 13)
$labelGFlags.Text = "BitMask: 0x0"
$labelGFlags.BackColor = [System.Drawing.Color]::Transparent
$labelGFlags.ForeColor = [System.Drawing.Color]::White
$tabGFlags.Controls.Add($labelGFlags)

# ResetMask
$btnResetFlags = New-Object System.Windows.Forms.Button
$btnResetFlags.Location = New-Object System.Drawing.Point(255, 255)
$btnResetFlags.Size = New-Object System.Drawing.Size(90, 20)
$btnResetFlags.Text = "ResetMask"
$btnResetFlags.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnResetFlags.BackColor = [System.Drawing.Color]::FromArgb(66, 66, 66)
$btnResetFlags.ForeColor = [System.Drawing.Color]::White
$btnResetFlags.FlatAppearance.BorderSize = 0
$tabGFlags.Controls.Add($btnResetFlags)
$btnResetFlags.Add_Click({
    Reset-Checkboxes -parentControl $tabGFlags

    $global:bitmaskGFlags = 0
    $labelGFlags.Text = "BitMask: 0x{0:X}" -f $global:bitmaskGFlags
})

# Configuración de posición inicial y dimensiones del área visible
$startX = 180
$startY = 40
$currentX = $startX
$currentY = $startY
$columnWidth = 60  # Ancho de la columna
$rowHeight = 30     # Espacio entre filas
$maxCheckboxesPerColumn = 7  # Número máximo de CheckBoxes por columna
$checkboxCount = 0  # Contador de CheckBoxes en la columna actual

$checkboxesFlags = @()

foreach ($flag in $flags) {
    # Crear CheckBox
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $flag.Abbreviation
    $checkbox.Location = New-Object System.Drawing.Point($currentX, $currentY)
    $checkbox.Size = New-Object System.Drawing.Size(55, 20)  # Ajustar el tamaño del CheckBox
    $checkbox.BackColor = [System.Drawing.Color]::Transparent
    $checkbox.ForeColor = [System.Drawing.Color]::White
    $tabGFlags.Controls.Add($checkbox)

    $checkbox.Add_Click({
        Update-FlagsMask
    })

    $checkboxesFlags += [PSCustomObject]@{ CheckBox = $checkbox; Option = $flag }

    # Añadir SymbolicName al ToolTip
    $tooltip.SetToolTip($checkbox, $flag.Description)

    # Ajustar la posición para el próximo CheckBox
    $checkboxCount++
    $currentY += $rowHeight

    # Si se ha alcanzado el número máximo de CheckBoxes en la columna, mover a la siguiente columna
    if ($checkboxCount -ge $maxCheckboxesPerColumn) {
        $checkboxCount = 0
        $currentY = $startY
        $currentX += $columnWidth
    }
}

$tab.TabPages.Add($tabIfeo)
$tab.TabPages.Add($tabMit)
$tab.TabPages.Add($tabGFlags)
$form.Controls.Add($tab)

$form.ShowDialog()
