
  # Test ARM template file with parameters, variables, functions, resources and outputs:
   $params = @{
    TemplatePath = 'C:\Users\syam3\Desktop\Refferencetemplates\vm\vm\azuredeploy.json'
    parameters = 'virtualMachineName', 'adminUsername', 'virtualNetworkResourceGroup', 'virtualNetworkName', 'adminPassword', 'subnetName'
    variables = 'nicName', 'publicIpAddressName', 'subnetRef', 'virtualMachineName', 'vnetId'
    resources = 'Microsoft.Compute/virtualMachines', 'Microsoft.Network/networkInterfaces', 'Microsoft.Network/publicIpAddresses'
    outputs = 'adminUsername'
  }
  .\pestertest.ps1 @params
  
  [CmdLetBinding()]

param (

	[Parameter(Mandatory=$true)]
	[string]$TemplatePath,

	[Parameter(Mandatory=$true)]
	[string[]]$parameters,
	
	[Parameter(Mandatory=$true)]
	[string[]]$variables,
	
	[Parameter(Mandatory=$false)]
	[string[]]$functions,

	[Parameter(Mandatory=$true)]
	[string[]]$resources,

	[Parameter(Mandatory=$true)]
	[string[]]$outputs
)

#variables
$requiredElements = New-object System.Collections.ArrayList
$optionalElements = New-Object System.Collections.ArrayList
[void]$requiredElements.Add('$schema')
[void]$requiredElements.Add('contentversion')
[void]$requiredElements.Add('resources')

[void]$optionalElements.Add('parameters')
[void]$optionalElements.Add('variables')
[void]$optionalElements.Add('outputs')

#Read template file
$TemplateContent = Get-Content $TemplatePath -Raw -ErrorAction SilentlyContinue
$TemplateJson = ConvertFrom-Json -InputObject $TemplateContent -ErrorAction SilentlyContinue
If ($TemplateJson)
{
  $TemplateElements = $TemplateJson.psobject.Properties.name.tolower()
} else {
  $TemplateElements = $null
}

#determine what tests to perform
If ($PSBoundParameters.ContainsKey('parameters'))
{
  $bCheckParameters = $true
}

If ($PSBoundParameters.ContainsKey('variables'))
{
  $bCheckVariables = $true
}

If ($PSBoundParameters.ContainsKey('outputs'))
{
  $bCheckOutputs = $true
}

#Pester tests
Describe 'ARM Template Validation' {
	Context 'Template File Validation' {
		It 'Template File Exists' {
			Test-Path $TemplatePath -PathType Leaf -Include '*.json' | Should Be $true
		}

		It 'ARM Template is a valid JSON file' {
			$TemplateContent | ConvertFrom-Json -ErrorAction SilentlyContinue | Should Not Be $Null
	  }
  }

  Context 'Template Content Validation' {
      It "Contains all required elements" {
      $bValidRequiredElements = $true
      Foreach ($item in $requiredElements)
      {
        if (-not $TemplateElements.Contains($item))
        {
          $bValidRequiredElements = $false
          Write-Output "template does not contain '$item'"
        }
      }
      $bValidRequiredElements | Should be $true
    }

    It "Only contains valid elements" {
      $bValidElements = $true
      Foreach ($item in $TemplateElements)
      {
        if ((-not $requiredElements.Contains($item)) -and (-not $optionalElements.Contains($item)))
        {
          $bValidElements = $false
        }
      }
      $bValidElements | Should be $true
    }

    It "Has valid Content Version" {
      If ($TemplateJson.contentVersion -match '^[0-9]+.[0-9]+.[0-9]+.[0-9]+$')
      {
        $bValidContentVersion = $true
      } else {
        $bValidContentVersion = $false
      }
      $bValidContentVersion | Should be $true
    }
    
    If ($bCheckParameters -eq $true)
    {
      It "Only has approved parameters" {
        $parametersFromTemplateFile = $TemplateJson.parameters.psobject.Properties.name | Sort-Object
        $strParametersFromTemplateFile = $parametersFromTemplateFile -join ','
        $parameters = $parameters | Sort-Object
        $strParameters = $parameters -join ','
        $strParametersFromTemplateFile | Should be $strParameters
      }
    }

    if ($bCheckVariables)
    {
      It "Only has approved variables" {
        $variablesFromTemplateFile = $TemplateJson.variables.psobject.Properties.name | Sort-Object
        $variables = $variables | Sort-Object
        $strVariablesFromTemplate = $variablesFromTemplateFile -join ','
        $strVariables = $variables -join ','
        $strVariablesFromTemplate | Should be $strVariables
      }
    }
    

    It "Only has approved resources" {
      $resourcesFromTemplate = $TemplateJson.resources.type | Sort-Object
      $strResourcesFromTemplate = $resourcesFromTemplate -join ','
      $resources = $resources | Sort-Object
      $strResources = $resources -join ','
      $strResourcesFromTemplate | Should be $strResources
    }

    If ($bCheckOutputs)
    {
      It "Only has approved outputs" {
      $outputsFromTemplate = $TemplateJson.outputs.psobject.Properties.name | Sort-Object
      $strOutputsFromTemplate = $outputsFromTemplate -join ','
      $outputs = $outputs | Sort-Object
      $strOutputs = $outputs -join ','
      $strOutputsFromTemplate | Should be $strOutputs
    }
    }
  }
}

#Done