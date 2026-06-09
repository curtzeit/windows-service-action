Param(
    [parameter(Mandatory = $true)]
    [ValidateSet('start', 'stop', 'restart')]
    [string]$action,

    [parameter(Mandatory = $true)]
    [string]$service_name,

    [parameter(Mandatory = $true)]
    [string]$server,

    [parameter(Mandatory = $true)]
    [string]$user_id,

    [parameter(Mandatory = $true)]
    [SecureString]$password
)

$title_verb = (Get-Culture).TextInfo.ToTitleCase($action)
$display_action = "Windows Service $title_verb"

switch ($action) {
    "start"   { $past_tense = "ed";  break; }
    "restart" { $past_tense = "ed";  break; }
    "stop"    { $past_tense = "ped"; break; }
}
$display_action_past_tense = "$display_action$past_tense"

Write-Output $display_action

# Establish Remote Session
$credential = [PSCredential]::new($user_id, $password)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
$session = New-PSSession $server -SessionOption $so -UseSSL -Credential $credential

$script = {
    # Relies on WebAdministration Module being installed on the remote server
    # This should be pre-installed on Windows 2012 R2 and later
    # https://docs.microsoft.com/en-us/powershell/module/?term=webadministration
    
    # Check if the service exists natively
    $service = Get-Service -Name $Using:service_name -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        Write-Error "Service not found: $Using:service_name"
        return
    }

    # Execute Action natively using modern PowerShell cmdlets
    switch ($Using:action) {
        "stop" {
            if ($service.Status -eq 'Running') {
                Write-Output "Stopping service: $Using:service_name..."
                Stop-Service -Name $Using:service_name -Force
            } else {
                Write-Output "Service $Using:service_name is already stopped."
            }
        }
        "start" {
            if ($service.Status -ne 'Running') {
                Write-Output "Starting service: $Using:service_name..."
                Start-Service -Name $Using:service_name
            } else {
                Write-Output "Service $Using:service_name is already running."
            }
        }
        "restart" {
            Write-Output "Restarting service: $Using:service_name..."
            Restart-Service -Name $Using:service_name -Force
        }
    }
}

# Execute on remote server
Invoke-Command `
    -Session $session `
    -ScriptBlock $script

Write-Output "$display_action_past_tense."