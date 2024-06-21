# Ifeo-Utility
pequeño script para configurar algunas caracteristicas de IFEO

![image](https://github.com/LuSlower/Ifeo-Utility/assets/148411728/79676cb0-d2ef-4c3f-8a52-57a0b05bed39)

> IFEO, "Image File Execution Options" (Opciones de Ejecución de Archivos de Imagen), es una característica de Windows que permite la configuración de cómo se ejecutan ciertas aplicaciones. Esta configuración se realiza a través del registro de Windows y puede ser utilizada para diversas tareas de depuración y control de aplicaciones.

Usos de IFEO
* Depuración: IFEO se utiliza frecuentemente para depurar aplicaciones. Configurando una entrada de IFEO para una aplicación específica, los desarrolladores pueden hacer que la aplicación se ejecute bajo un depurador automáticamente cada vez que se inicia.

* Redirección de Ejecución: IFEO puede redirigir la ejecución de una aplicación a otra. Por ejemplo, en lugar de ejecutar un programa original, se puede ejecutar un programa modificado o alternativo.

* Bloqueo de Aplicaciones: Administradores de sistemas pueden usar IFEO para bloquear la ejecución de ciertas aplicaciones. Configurando IFEO, pueden hacer que cualquier intento de ejecutar una aplicación en particular simplemente no haga nada o ejecute un programa diferente.

* Uso en Malware: Desafortunadamente, también se ha visto que IFEO se utiliza en técnicas de malware para interceptar la ejecución de aplicaciones y redirigirlas a código malicioso.

> Configuración de IFEO
La configuración de IFEO se realiza mediante la edición del registro de Windows. Aquí tienes un ejemplo básico de cómo configurar IFEO para una aplicación en particular:

ejecuta regedit o regedt32 desde el menú de inicio o desde ejecutar (win +`r)

Clave IFEO:
`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options`

Debes crear una subclave dentro de Image File Execution Options con el nombre del ejecutable que deseas configurar. por ejemplo, si deseas configurar `notepad.exe`, crearías una clave llamada `notepad.exe`.

Agregar Valores a la Clave de la Aplicación:

`Debugger`: Para hacer que la aplicación se ejecute bajo un depurador, crea un nuevo valor de cadena llamado Debugger y establece su valor al path del depurador, por ejemplo:
swift

`"C:\path\to\debugger.exe"`

Supongamos que deseas depurar notepad.exe utilizando el depurador windbg.exe. Aquí están los pasos:

> Abre el editor de registro (regedit).
Navega a `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options`
Crea una nueva clave llamada notepad.exe.
Dentro de notepad.exe, crea un nuevo valor de cadena llamado Debugger.
Establece el valor de Debugger a:
swift

`"C:\path\to\windbg.exe"`

