#$ErrorActionPreference = "Ignore"
#$WarningPreference = "Ignore"
Function WriteXmlToScreen ([xml]$xml) #just to make it clean XML code...
{
    #Write-Host Whoami
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    Write-Output $StringWriter.ToString();
}
#Import-Module Az.Accounts
#Install-PackageProvider nuget -Force
#Install-Module AzureRM -AllowClobber -Force
#Import-Module AzureRM
#Install-Module AzureRM.Sql -Force

[String]$ResourceGroupName=$args[0]
[String]$ServerName=$args[1]
[String]$ElasticPoolName=$args[2]
[String]$ServicePrincipal=$args[3]
[String]$SecretPwd=$args[4]
[String]$SubscriptionId=$args[5]

#############################################################################################################
#if([String]::IsNullOrEmpty($ResourceGroupName)){$ResourceGroupName="ResourceGroupName"}
#if([String]::IsNullOrEmpty($ServerName)){$ServerName="SqlServerName"}
#if([String]::IsNullOrEmpty($ElasticPoolName)){$ElasticPoolName="ElasticPoolName"}
#if([String]::IsNullOrEmpty($ServicePrincipal)){$ServicePrincipal="user@domain.com"}
#if([String]::IsNullOrEmpty($SecretPwd)){$SecretPwd="password"}
#############################################################################################################

$passwd = ConvertTo-SecureString $SecretPwd -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($ServicePrincipal, $passwd)

Login-AzureRmAccount -Credential $pscredential
Select-AzureRmSubscription -SubscriptionId $SubscriptionId
#$sqlserver=Get-AzureRmSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName

$pool=Get-AzureRmSqlElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ElasticPoolName $ElasticPoolName
$metricas=@(Get-AzureRmMetricDefinition -ResourceId $pool.ResourceId).name.Value #("dtu_consumption_percent","storage_percent","allocated_data_storage_percent")
$items=Get-AzureRmMetric -ResourceId $pool.ResourceId -AggregationType Average -TimeGrain 00:01:00 -StartTime ((Get-Date).AddMinutes(-5)) -EndTime (Get-Date) -MetricName $metricas -WarningAction Ignore

$XML = "<PRTG>"
foreach($item in $items)
{    
    #$XML += "<result><channel>A_Name</channel><value>150</value><CustomUnit>Value</CustomUnit></result>"
    $res=$item.Data[$item.Data.Count-3].Average
    if($res -Match ".")
    {
        $XML += "<result><Float>1</Float><channel>"+$item.Name.Value+"</channel><value>"+$item.Data[$item.Data.Count-3].Average+"</value><CustomUnit>Value</CustomUnit></result>"
    }
    else
    {
        $XML += "<result><channel>"+$item.Name.Value+"</channel><value>"+$item.Data[$item.Data.Count-3].Average+"</value><CustomUnit>Value</CustomUnit></result>"
    }
}
$XML += "</PRTG>"

WriteXmlToScreen "$XML"

