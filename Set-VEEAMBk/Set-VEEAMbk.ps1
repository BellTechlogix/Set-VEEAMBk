<#
	Set=VEEAMBk.ps1
	Created by - Kristopher Roy
	Original Code snippets - Provided by James Hudgens
	Created on - 12/04/17
	The purpose of this script is to modify a tape VEEAM Job to add files dynamically from a designated directory and sub folders recursively.
#>

# Load Veeam Snapin
If (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) 
{
	If (!(Add-PSSnapin -PassThru VeeamPSSnapIn)) 
	{
		Write-Error "Unable to load Veeam snapin" -ForegroundColor Red
		cmd /c pause | out-null
		Exit
	}
}

#Get all txt and bak files older than a day
$files = Get-ChildItem '\\jax-dxi7500\jaxsqlback' -recurse -include @("*.bak*","*.txt*")| Where-Object { $_.CreationTime -le  (get-date).AddDays(-1) }

#select the newest of the files
$filearray = @(
    $files|Where-Object { $_.Extension -like ".txt"}|group directory|foreach{@($_.group | sort {[datetime]$_.creationtime} -desc)[0]}
    $files|Where-Object { $_.Extension -like ".bak"}|group directory|foreach{@($_.group | sort {[datetime]$_.creationtime} -desc)[0]}
)


#Create VEEAM Job
$job = Get-VBRTapeJob -name "jax-dxi7500test"
#check if VEEAM Job exists, fail if it does not
IF ($job -eq $null -or $job -eq "")
{
	Write-Error "Unable to find VEEAM Job" -ForegroundColor Red
	cmd /c pause | out-null
	Exit
}

#create vbrarray
$vbrarray = FOREACH($file in $filearray)
{
    New-VBRFileToTapeObject -Path $file.FullName
}

#set new job and object $vbarray as source
Set-VBRFileToTapeJob -Job $job -Object $vbrarray
