<#
.SYNOPSIS
  Convert Sentinel YAML formated KQL Detection and Hunting Queries to an ARM Template.
.DESCRIPTION
  This script converts Sentinel YAML formated KQL Detection and Hunting Queries to an ARM Template.
  THe input format of the YAML template should be in occordance to the Query Style guide found in the Azure-Sentinel Query Style Guide.

  Ref:
    - https://github.com/Azure/Azure-Sentinel/tree/master/Hunting%20Queries
    - https://github.com/Azure/Azure-Sentinel/wiki/Query-Style-Guide

.PARAMETER YamlPath
    Direct path to the YAML formated Sentinel Hunting Query that you want to convert to an ARM Template.
.INPUTS
  PARAMETER: -YamlPath
.OUTPUTS
  <name>.json
.NOTES
  Version:        1.0
  Author:         Simon Lavigne
  
.EXAMPLE
  ConvertFrom-SentinelYaml -YamlPath 'Hunting queries\AccountAddedToPrivGroup.yaml'
#>

function ConvertFrom-SentinelYaml
{
    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$YamlPath
    )

    Write-Host "Converting " + $YamlPath + " to ARM"

    $YamlContent = Get-Content $YamlPath
    $obj = $YamlContent | ConvertFrom-Yaml -Ordered

    $query = $obj.query | ConvertTo-Json
    $description = $obj.Description.Replace("'", "")  | ConvertTo-Json
    $tactics = $obj.tactics -join ","
    $techniques = $obj.relevantTechniques
    $name = $obj.name

$body = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workspace": {
            "type": "String"
        },
        "query_id": {
            "defaultValue": "[newGuid()]",
            "type": "String"
        }
    },
    "functions": [],
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.OperationalInsights/workspaces/savedSearches",
            "apiVersion": "2020-08-01",
            "name": "[concat(parameters('workspace'), '/',parameters('query_id'))]",
            "properties": {
                "etag": "*",
                "Category": "Hunting Queries",
                "DisplayName": "$name", 
                "query": $query,
                "Tags": [
                    {
                        "Name": "description",
                        "Value": $description
                    },
                    {
                        "Name": "tactics",
                        "Value": "$tactics"
                    },
                    {
                        "name": "techniques",
                        "value": "$techniques"
                    }
                ]
            }
        }
    ],
    "outputs": {}
}
"@

    $body | Out-File (-join($name,".json")).Replace(" ","")
}
