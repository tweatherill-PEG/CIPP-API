function Invoke-CIPPStandardExcludedfileExt {
    <#
    .FUNCTIONALITY
    Internal
    #>
    param($Tenant, $Settings)
    $CurrentInfo = New-GraphGetRequest -Uri 'https://graph.microsoft.com/beta/admin/sharepoint/settings' -tenantid $Tenant -AsApp $true
    $Exts = ($Settings.ext -replace ' ', '') -split ','
    
    $MissingExclutions = foreach ($Exclusion in $Exts) {
        if ($Exclusion -notin $CurrentInfo.excludedFileExtensionsForSyncApp) {
            $Exclusion
        }
    }
    Write-Host "MissingExclutions: $($MissingExclutions)"


    If ($Settings.remediate) {

        if ($MissingExclutions) {
            Write-Host "CurrentInfo.excludedFileExtensionsForSyncApp: $($CurrentInfo.excludedFileExtensionsForSyncApp)"
            Write-Host "Exts: $($Exts)"
            try {
                $body = ConvertTo-Json -InputObject @{ excludedFileExtensionsForSyncApp = @($Exts) }
                $null = New-GraphPostRequest -tenantid $tenant -Uri 'https://graph.microsoft.com/beta/admin/sharepoint/settings' -AsApp $true -Type patch -Body $body -ContentType 'application/json'
                Write-LogMessage -API 'Standards' -tenant $tenant -message "Added $($Settings.ext) to excluded synced files" -sev Info
            } catch {
                Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to add $($Settings.ext) to excluded synced files: $($_.exception.message)" -sev Error
            }
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message "Excluded synced files already contains $($Settings.ext)" -sev Info
        }
    }

    if ($Settings.alert) {

        if ($MissingExclutions) {
            Write-LogMessage -API 'Standards' -tenant $tenant -message "Excluded synced files does not contain $($MissingExclutions -join ',')" -sev Alert
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message "Excluded synced files contains $($Settings.ext)" -sev Info
        }
    }

    if ($Settings.report) {
        Add-CIPPBPAField -FieldName 'ExcludedfileExt' -FieldValue $CurrentInfo.excludedFileExtensionsForSyncApp -StoreAs json -Tenant $tenant
    }
}
