clear-host

$sourceGroupsToExport = @('*','perm_*','user_*')


function GetGroups($organization, $project)
{
    write-host "fetching groups Org : $organization, Project : "$project -ForegroundColor Yellow
    return az devops security group list --organization $organization --project $project  | ConvertFrom-Json    
}

function GetGroupMembershipList($group, $organization)
{
    return az devops security group membership list --id $group.descriptor --organization $organization | ConvertFrom-Json    
}

function GetGroupUsers($sourceOrganization, $sourceProject)
{
    $sourceGroups = GetGroups -organization $sourceOrganization -project $sourceProject 

    Foreach ($sourceGroup in $sourceGroups.graphGroups | Sort-Object -Property 'displayName')
    {
        foreach($sourceGroupToExport in $sourceGroupsToExport)
        { 
            if($sourceGroup.displayName.ToLowerInvariant()  -clike $sourceGroupToExport.ToLowerInvariant()) 
            {            
                write-host "Name : $($sourceGroup.displayName)" -ForegroundColor Yellow  
                write-host "Description : $($sourceGroup.description)" -ForegroundColor Yellow                 
            
                $sourceGroupMembersResult = GetGroupMembershipList -group $sourceGroup -organization $sourceOrganization
                $properties = $sourceGroupMembersResult | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
            
                $sourceGroupMembers = @()
                $sourceGroupMembers += $properties.ForEach({$sourceGroupMembersResult.$_})

                foreach($sourceGroupMember  in $sourceGroupMembers)
                { 
                    write-host $sourceGroupMember.displayName $sourceGroupMember.mailAddress                   
                }            
            }
        }
    }
}

function DeleteGroup($group, $organization, $project)
{
    write-host "deleting : "$group.displayName -ForegroundColor Yellow
    az devops security group delete --id $group.descriptor --org $organization --yes --output table  
    write-host "done" -ForegroundColor Green
}

function CreateGroup($group, $organization, $project)
{
    write-host "creating : "$group.displayName -ForegroundColor Yellow
    if([string]::IsNullOrEmpty($group.description))
    {
        $group.description = $group.displayName
    }
    return az devops security group create --name $group.displayName --organization $organization --project $project --description $group.description | ConvertFrom-Json    
}

function AddUser($organization, $group, $member)
{
    write-host "adding : "$member.displayName -ForegroundColor Yellow

    $member
    
    return az devops security group membership add --group-id $group.descriptor --organization $organization --member-id $member.descriptor --output table    
}

function ExportUsers($sourceOrganization, $sourceProject, $targetOrganization, $targetProject)
{
    $sourceGroups = GetGroups -organization $sourceOrganization -project $sourceProject 

    Foreach ($sourceGroup in $sourceGroups.graphGroups | Sort-Object -Property 'displayName')
    {
        foreach($sourceGroupToExport in $sourceGroupsToExport)
        { 
            if($sourceGroup.displayName.ToLowerInvariant()  -clike $sourceGroupToExport.ToLowerInvariant()) 
            {            
                write-host $sourceGroup.displayName 

                $targetGroup = CreateGroup -group $sourceGroup -organization $targetOrganization -project $targetProject
                #$targetGroup 
            
                $sourceGroupMembersResult = GetGroupMembershipList -group $sourceGroup -organization $sourceOrganization
                $properties = $sourceGroupMembersResult | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
            
                $sourceGroupMembers = @()
                $sourceGroupMembers += $properties.ForEach({$sourceGroupMembersResult.$_})

                foreach($sourceGroupMember  in $sourceGroupMembers)
                { 
                    #write-host $sourceGroupMember.displayName $sourceGroupMember.mailAddress 
                    $user = AddUser -organization $targetOrganization -group  $targetGroup -member $sourceGroupMember 
                    #$user
                }            
            }
        }
    }
}

function DeleteGroups($organization, $project)
{
    $sourceGroups = GetGroups -organization $organization -project $project 

    Foreach ($sourceGroup in $sourceGroups.graphGroups | Sort-Object -Property 'displayName')
    {
        foreach($sourceGroupToExport in $sourceGroupsToExport)
        { 
            if($sourceGroup.displayName.ToLowerInvariant()  -clike $sourceGroupToExport.ToLowerInvariant()) 
            {   
                DeleteGroup -group $sourceGroup -organization $organization -project $project                        
            }
        }
    }
}

[string]$sourceOrganization = 'https://dev.azure.com/basf4dev'
[string]$sourceProject = 'trinamiXExternal'

[string]$destOrganization = "https://dev.azure.com/trinamiX/"
[string]$destProject = 'trinamiXImaging_TestPlan'

#ExportUsers -sourceOrg $sourceOrganization -sourceProject $sourceProject -targetOrganization $destOrganization -targetProject $destProject
#DeleteGroups -organization $destOrganization -project $destProject
GetGroupUsers -sourceOrg $sourceOrganization -sourceProject $sourceProject