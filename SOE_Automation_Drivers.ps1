[CmdletBinding()]

# Global Input Parameters
param
(
       [switch] $install,
       [switch] $uninstall
)

# Import Statements
Add-Type -Path "C:\Apps\WinSCP\WinSCPnet.dll"

# Global Variables
$Global:MODEL = $(Get-WmiObject -Class Win32_ComputerSystem | % { $_.Model }).trim().replace(' ', '_')
$Global:REMOTE_ROOT = "/var/www/html/files/"
$Global:REMOTE_DRIVER_DIR = $(Join-Path -Path $Global:REMOTE_ROOT -ChildPath $Global:MODEL).replace('\','/')
$Global:LOCAL_ROOT = "C:\Apps\Drivers"
$Global:LOCAL_DRIVER_DIR = Join-Path -Path $Global:LOCAL_ROOT -ChildPath $Global:MODEL

# Check and Initialize Local Directory Structure
function setupDriverDirectory()
{
       if ((Test-Path -Path $Global:LOCAL_ROOT) -eq 1)
       {
              Write-Debug "$Global:LOCAL_ROOT exists."
              
              pullDownDrivers
       }
       else
       {
              New-Item -ItemType Directory -Path $Global:LOCAL_ROOT
              setupDriverDirectory
       }
}

# SCP Drivers from Remote Server
function pullDownDrivers()
{
       try
       {
              # Setup session options
              $sessionOptions = New-Object WinSCP.SessionOptions
              $sessionOptions.Protocol = [WinSCP.Protocol]::Sftp
              $sessionOptions.HostName = "192.168.240.100"
              $sessionOptions.UserName = "webfiles"
              $sessionOptions.Password = "Password"
              $sessionOptions.SshHostKeyFingerprint = ""
              
              # Create Session Object
              $session = New-Object WinSCP.Session
              
              try
              {
                     # Open Session with the above declared options.
                     $session.Open($sessionOptions)
                     
                     # Check if session is open
                     if ($session.Opened)
                     {
                           Write-Debug "Session Opened"
                           
                           # Sychronize the remote Files and Directory structure with the local
                           $Local:synchronizationResult = $session.SynchronizeDirectories([WinSCP.SynchronizationMode]::Local, $Global:LOCAL_ROOT, $Global:REMOTE_DRIVER_DIR, $False)
                           
                     }
                     else
                     {
                           Write-Warning "Session Not Open"
                     }
                     
              }
              finally
              {
                     # Dispose of the session, and clean up used resources.
                     $session.Dispose()
              }
              
       }
       catch [Exception]
       {
              # Write Execption message to console
              Write-Error $_.Exception.Message
              exit 1
       }
}

# Generic Driver Installation Function
function installDrivers()
{
       Set-Location -Path "$Global:LOCAL_ROOT"
       #$Local:cmd = "pnputil -i -a *.inf"

       & "pnputil" -i -a *.inf
       #-ArgumentList "-i"
}

function activation()
{
       Set-Location -Path "C:\Program Files\Microsoft Office\Office15\"
       & "cscript" C:\Windows\system32\slmgr.vbs 
       & "cscript" C:\Windows\system32\slmgr.vbs -ato
       & "cscript" ospp.vbs /inpkey:
       & "cscript" ospp.vbs /act
}

# Generic Driver Installation Function
function GFX()
{
       Set-Location -Path "$Global:LOCAL_ROOT"
       #$Local:cmd = "pnputil -i -a *.inf"

       & ".\gfx.exe" -s -A -s -b
       #-ArgumentList "-i"
}


# Entry Point into script
function Main()
{
       if ($install)
       {
              setupDriverDirectory
              installDrivers
              activation
              GFX
       }
}

Main


