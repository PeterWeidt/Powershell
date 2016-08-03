$Global:Exclusion = "SYSTEM","S1*", $env:ComputerName, "*DWM*", "3", "*HealthMailbox*", "8"
$Global:Event = $(Get-EventLog -LogName Security | Where-Object {$_.EventID -eq 4624} | Select-Object -First 1 );

$PRDSMTP="server"
$HOSMTP="server"

$Global:GetType = foreach ($line in $($Global:Event.Message.split("`n")))
{
    if ($line -like "*Logon Type*")
    {
        $i++
        if ($i -le 1)
        {
			$Alert = $line.split(':')[1].trim()
        }
    }
};

if ($Global:Exclusion -like "*$Alert*")
{
    write-host "$Alert on Exclusion" >> "C:\Scripts\Logs\log.txt"
	exit
}

$Global:EventDescription = $Global:Event.Message | % { $_.split('.')[0] }
$i = 0
$Global:GetLocation = $($env:ComputerName.Split('-')[2])

$Global:GetUser = foreach ($line in $($Global:Event.Message.split("`n")))
{
    if ($line -like "*Account Name*")
    {
        $i++
        if ($i -le 2)
        {
			$userName = $line.split(':')[1].trim()
			Write-Verbose "$userName"
        }
    }
};


if ($Global:Exclusion -like "*$($userName.replace('$',''))*")
{
    exit 0
}

if ($username -like "healthmailbox*") {exit 0}
if ($username -like "DWM*") {exit 0}

if ($Global:GetLocation -like "2*") 
{
    $Global:SMTPServer = "$PRDSMTP"
}
else
{
    $Global:SMTPServer = "$HOSMTP"
}

echo $Global:SMTPServer

      $messageParameters =
       @{
              Subject = "$username - $Global:EventDescription to $env:ComputerName";
              Body = $($Global:Event | format-list | Out-String);
              From = "$env:ComputerName <$env:ComputerName@company.com.au>";
              To = "peterweidt@company.com.au";
              SmtpServer = "$Global:SMTPServer";
       };

Write-Verbose "Sending Email with the following: $messageParameters"
Send-MailMessage @messageParameters
