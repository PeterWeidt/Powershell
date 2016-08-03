## Peter Weidt 03/08/2016 - Automatic linux posix attribute integration ##

$UIDLIST= New-Object System.collections.arraylist
$GROUP="GroupName"

## Find the largest ID ##
Function LargestUID
{
Get-AdGroupMember -Identity $GROUP | 
where {$_.objectclass -eq "user"} |
foreach { 
$ID=$(Get-AdUser $($_.distinguishedName) -properties *).uidnumber 
$UIDLIST.add("$ID") > $null
	}## End Foreach
$NEWUID=$($UIDLIST | measure -Maximum).Maximum
$NEWUID
}## End LargestUID 

## Add one to the largest UID for members with no UID set ##
Function AddUID
{
Get-AdGroupMember -Identity $GROUP | 
where {$_.objectclass -eq "user"} |
foreach { 
$ID=$(Get-AdUser $($_.distinguishedName) -properties *).uidnumber 

if ($ID -eq $null) {
LargestUID
$NewUID=LargestUID
$NewUID++
echo "$($_.samaccountname), ID Assigned: $NewUID"
get-aduser $($_.distinguishedName)|set-aduser -add @{loginshell="/bin/bash";unixhomedirectory="/home/$($_.Samaccountname)";uidnumber="$NewUID";gidnumber="$NewUID"}
		}## End if##
	}## End Foreach
}## End AddUID

AddUID
