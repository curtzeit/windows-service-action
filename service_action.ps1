Param(
    [parameter(Mandatory = $true)]
    [ValidateSet( 'start', 'stop', 'restart')]
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

$display_action = 'Windows Service'
$title_verb = (Get-Culture).TextInfo.ToTitleCase($action)

$display_action += " $title_verb"
$past_tense = "ed"
switch ($action) {
    "start" {}
    "restart" { break; }
    "stop" { $past_tense = "ped"; break; }
}
$display_action_past_tense = "$display_action$past_tense"

Write-Output $display_action

$credential = [PSCredential]::new($user_id, $password)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
$session = New-PSSession $server -SessionOption $so -UseSSL -Credential $credential

$script = {
    # Relies on WebAdministration Module being installed on the remote server
    # This should be pre-installed on Windows 2012 R2 and later
    # https://docs.microsoft.com/en-us/powershell/module/?term=webadministration

    # Only try to stop if it exists
$service = Get-Service -Name $Using:service_name -ErrorAction Stop

if ($null -ne $service) {
    if ($Using:action -eq 'stop' -or $Using:action -eq 'restart') {
        if ($service.Status -eq 'Running') {
            Write-Output "Stopping service: $Using:service_name"
            net stop $Using:service_name
        } else {
            Write-Output "Service $Using:service_name is not running, no need to stop."
        }
    }

    if ($Using:action -eq 'start' -or $Using:action -eq 'restart') {
        if ($service.Status -ne 'Running') {
            Write-Output "Starting service: $Using:service_name"
            net start $Using:service_name
        } else {
            Write-Output "Service $Using:service_name is already running."
        }
    }
} else {
    Write-Output "Service not found: $Using:service_name"
}
}

Invoke-Command `
    -Session $session `
    -ScriptBlock $script

Write-Output "$display_action_past_tense."
