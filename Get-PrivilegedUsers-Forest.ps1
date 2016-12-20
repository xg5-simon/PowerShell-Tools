#Requires -Version 3.0

<#  
    .SYNOPSIS  
       Returns a summary of privileged user accounts in a forest.
    .DESCRIPTION
       Performs Active Directory privileged user checks based on LDAP queries.
       Original script from https://gallery.technet.microsoft.com/scriptcenter/List-Membership-In-bff89703  
    .INPUTS
       None. You cannot pipe objects to this script.
    .OUTPUTS
       This script creates a CSV file.
    .NOTES
    NAME: Get-Privileged-Users-Forest.ps1
    ORIGINAL AUTHOR: Doug Symalla
    MODIFIED: Simon
    VERSION: 1.7
    LAST EDIT: 23rd of Nov 2016

    TODO: Prompt for user authentication when connecting to Forest without a trust.

    .PARAMETERS
        $ForestName : Set the name forest or domain to query. This script must be run with user level privileges from the forest or domain.
        $colAllPrivUsers | Export-CSV -NoTypeInformation ".\_privileged_users.csv" : Configure the name of the csv file.

#> 

$Global:ForestName 

function getMemberExpanded 
{ 
    param ($dn) 
                 
    $adobject = [adsi]"LDAP://$dn" 
    $colMembers = $adobject.properties.item("member") 
    Foreach ($objMember in $colMembers) 
    { 
        $objMembermod = $objMember.replace("/","\/") 
        $objAD = [adsi]"LDAP://$objmembermod" 
        $attObjClass = $objAD.properties.item("objectClass") 
        if ($attObjClass -eq "group") { 
            getmemberexpanded $objMember
        }    
            else 
        { 
            $colOfMembersExpanded += ,$objMember 
        } 
    }     
$colOfMembersExpanded  
}     

# Function to Calculate Password Age #
Function getUserAccountAttribs 
{ 
    param($objADUser,$parentGroup) 
    $objADUser = $objADUser.replace("/","\/") 
    $adsientry=new-object directoryservices.directoryentry("LDAP://$objADUser") 
    $adsisearcher=new-object directoryservices.directorysearcher($adsientry) 
    $adsisearcher.pagesize=1000 
    $adsisearcher.searchscope="base" 
    $colUsers=$adsisearcher.findall() 
    
    foreach($objuser in $colUsers) 
    { 
        $dn=$objuser.properties.item("distinguishedname")
        $sam=$objuser.properties.item("samaccountname") 
        $attObjClass = $objuser.properties.item("objectClass") 
        $domain = ((($dn -replace "(.*?)DC=(.*)",'$2') -replace "DC=","") -replace ",",".")
            
        If ($attObjClass -eq "user") 
        { 
            $cn=$objuser.properties.item("cn")
            $userPrincipalName=$objuser.properties.item("userPrincipalName")
            $personalTitle=$objuser.properties.item("personalTitle")
            $displayName=$objuser.properties.item("displayName")
            $givenName=$objuser.properties.item("givenName")
            $sn=$objuser.properties.item("sn")
            $mail=$objuser.properties.item("mail")
            $telephoneNumber=$objuser.properties.item("telephoneNumber")
            $mobile=$objuser.properties.item("mobile")
            $manager=$objuser.properties.item("manager")
            $company=$objuser.properties.item("company")
            $department=$objuser.properties.item("department")
            $description=$objuser.properties.item("description")
            $l=$objuser.properties.item("l")
            $co=$objuser.properties.item("co")            
            $physicalDeliveryOfficeName=$objuser.properties.item("physicalDeliveryOfficeName")
            $whenCreated=$objuser.properties.item("whenCreated")
            $accountExpires=$objuser.properties.item("accountExpires")            
            $whenChanged=$objuser.properties.item("whenChanged")
            $lastLogon=$objuser.properties.item("lastLogon")
            $lastLogonTimestamp=$objuser.properties.item("lastLogonTimestamp")
            $logonCount=$objuser.properties.item("logonCount")
            $lockoutTime=$objuser.properties.item("lockoutTime")
            $badPwdCount=$objuser.properties.item("badPwdCount")
            $userAccountControl=$objuser.properties.item("userAccountControl")
            $homeDirectory=$objuser.properties.item("homeDirectory")
            $pwdLastSet=$objuser.properties.item("pwdLastSet") 
            if ($pwdLastSet -gt 0) 
                { 
                    $pwdLastSet=[datetime]::fromfiletime([int64]::parse($pwdLastSet)) 
                        $PasswordAge=((get-date) - $pwdLastSet).days 
                } 
                Else {$PasswordAge = "<Not Set>"}                                                                         
            $uac=$objuser.properties.item("useraccountcontrol") 
                $uac=$uac.item(0) 
            if (($uac -bor 0x0002) -eq $uac) {$disabled="TRUE"} 
                else {$disabled = "FALSE"} 
                if (($uac -bor 0x10000) -eq $uac) {$passwordneverexpires="TRUE"} 
                else {$passwordNeverExpires = "FALSE"} 
        }                                                         
            $record = "" | select-object SAM,DN,cn,userPrincipalName,displayName,personalTitle,givenName,sn,mail,telephoneNumber,mobile,
                                         manager,company,department,description,l,co,physicalDeliveryOfficeName,
                                         whenCreated,accountExpires,whenChanged,lastLogon,lastLogonTimestamp,logonCount,lockoutTime,badPwdCount,useraccountcontrol,
                                         homeDirectory,pwdLastSet,MemberOf,pwdAge,disabled,pWDneverExpires,domain
            $record.SAM = [string]$sam 
            $record.DN = [string]$dn 
            $record.cn = [string]$cn
            $record.userPrincipalName = [string]$userPrincipalName
            $record.displayName = [string]$displayName
            $record.personalTitle = [string]$personalTitle
            $record.givenName = [string]$givenName
            $record.sn = [string]$sn
            $record.mail = [string]$mail
            $record.telephoneNumber = [string]$telephoneNumber
            $record.mobile = [string]$mobile
            $record.manager = [string]$manager
            $record.company = [string]$company
            $record.department = [string]$department
            $record.description = [string]$description
            $record.l = [string]$l
            $record.co = [string]$co
            $record.physicalDeliveryOfficeName = [string]$physicalDeliveryOfficeName
            $record.whenCreated = [string]$whenCreated
            If ($accountExpires -eq 0 -Or $accountExpires -eq 9223372036854775807) {
                $record.accountExpires = "Never"
            } 
            Else {
                #$record.accountExpires = [DateTime]::FromFileTime([Int64][string]$accountExpires)
                $record.accountExpires = [string]$accountExpires
            }
            $record.whenChanged = [string]$whenChanged
            $record.lastLogon = [DateTime]::FromFileTime([Int64][string]$lastLogon)
            $record.lastLogonTimestamp = [DateTime]::FromFileTime([Int64][string]$lastLogonTimestamp)
            $record.logonCount = [string]$logonCount
            $record.lockoutTime = [string]$lockoutTime
            $record.badPwdCount = [string]$badPwdCount
            $record.useraccountcontrol = [string]$uac
            $record.homeDirectory = [string]$homeDirectory
            $record.pwdLastSet = [string]$pwdLastSet
            $record.memberOf = [string]$parentGroup 
            $record.pwdAge = $PasswordAge 
            $record.disabled= $disabled 
            $record.pWDneverExpires = $passwordNeverExpires
            $record.domain = [string]$domain
                                 
    }
      
    $record
    #Write-Host $record
     
}
<#
.Synopsis 
    Function to find all Privileged Groups in the Forest
#>
Function getForestPrivGroups 
{ 

    $ForestName = ''
    Write-Host ""
    Write-host "[+] Forest: $ForestName " -foregroundColor Green 

    $colOfDNs = @() 

    If (!$ForestName) {
        $Forest = [System.DirectoryServices.ActiveDirectory.forest]::getcurrentforest() 
    }
    Else {
        $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName)    
        $Forest = ([System.DirectoryServices.ActiveDirectory.Forest]::GetForest($adCtx))
    }

    $RootDomain = [string]($forest.rootdomain.name) 
    $forestDomains = $forest.domains 
    $colDomainNames = @() 

    ForEach ($domain in $forestDomains) 
    { 
        $domainname = [string]($domain.name) 
        $colDomainNames += $domainname 
    } 
         
    $ForestRootDN = FQDN2DN $RootDomain 
    $colDomainDNs = @()
      
    ForEach ($domainname in $colDomainNames) 
    { 
        $domainDN = FQDN2DN $domainname 
        Write-Host "    $domainDN" -foregroundColor Gray 
        $colDomainDNs += $domainDN     
    } 

    $GC = $forest.FindGlobalCatalog() 
    $adobject = [adsi]"GC://$ForestRootDN" 
    $RootDomainSid = New-Object System.Security.Principal.SecurityIdentifier($AdObject.objectSid[0], 0) 
    $RootDomainSid = $RootDomainSid.toString() 
    $colDASids = @() 
        
    ForEach ($domainDN in $colDomainDNs) 
    { 
        $adobject = [adsi]"GC://$domainDN" 
        $DomainSid = New-Object System.Security.Principal.SecurityIdentifier($AdObject.objectSid[0], 0) 
        $DomainSid = $DomainSid.toString() 
        $daSid = "$DomainSID-512" 
        $colDASids += $daSid 
    } 
             

    $colPrivGroups = @("S-1-5-32-544";"S-1-5-32-548";"S-1-5-32-549";"S-1-5-32-551";"$rootDomainSid-519";"$rootDomainSid-518") 
    $colPrivGroups += $colDASids 
                 
    $searcher = $gc.GetDirectorySearcher() 
       
    ForEach($privGroup in $colPrivGroups) 
    { 
        $searcher.filter = "(objectSID=$privGroup)" 
        $Results = $Searcher.FindAll() 
        ForEach ($result in $Results) 
        { 
            $dn = $result.properties.distinguishedname 
            $colOfDNs += $dn
        } 
    } 

$colofDNs 
} 

<#
.Synopsis 
    Function to Generate Domain DN from FQDN
#>
Function FQDN2DN 
{ 
    Param ($domainFQDN) 
    $colSplit = $domainFQDN.Split(".") 
    $FQDNdepth = $colSplit.length 
    $DomainDN = "" 
    For ($i=0;$i -lt ($FQDNdepth);$i++) 
    { 
        If ($i -eq ($FQDNdepth - 1)) {$Separator=""} 
        else {$Separator=","} 
        [string]$DomainDN += "DC=" + $colSplit[$i] + $Separator 
    } 
    $DomainDN 
} 

<#
.Synopsis 
    Main
#>
$forestPrivGroups = GetForestPrivGroups 
$colAllPrivUsers = @() 

$rootdse=new-object directoryservices.directoryentry("LDAP://rootdse") 

Foreach ($privGroup in $forestPrivGroups) 
{ 
    Write-Host "" 
    Write-Host "Enumerating $privGroup.." -foregroundColor yellow 
    $uniqueMembers = @() 
    $colOfMembersExpanded = @() 
    $colofUniqueMembers = @() 
    $members = getmemberexpanded $privGroup 

    If ($members) 
    { 
        $uniqueMembers = $members | sort-object -unique 
        $numberofUnique = $uniqueMembers.count 
    Foreach ($uniqueMember in $uniqueMembers) 
    { 
        $objAttribs = getUserAccountAttribs $uniqueMember $privGroup 
        $colOfuniqueMembers += $objAttribs            
    } 
        $colAllPrivUsers += $colOfUniqueMembers                             
    } 
    Else {$numberofUnique = 0} 
                 
    If ($numberofUnique -gt 25) 
    { 
        Write-host "...$privGroup has $numberofUnique unique members" -foregroundColor Red 
    } 
    Else { Write-host "...$privGroup has $numberofUnique unique members" -foregroundColor White } 
        ForEach($user in $colOfuniquemembers) 
        { 
            $userpwdAge = $user.pwdAge 
            $userSAM = $user.SAM 
            If ($userpwdAge -gt 365) 
                {Write-host "......$userSAM has a password age of $userpwdage" -foregroundColor Green} 
        }
} 

#Write-Host $ForestName

#Write-Output $colAllPrivUsers
$colAllPrivUsers | Export-CSV -NoTypeInformation ".\privileged_users.csv" 
