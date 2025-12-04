# Replace Zabbix agent with TAA agent in all template files

$files = Get-ChildItem -Path templates -Recurse -Filter "*.yaml" | Select-String -Pattern "Zabbix agent" -List | Select-Object -ExpandProperty Path -Unique

Write-Host "Total files to update: $($files.Count)"

$totalReplacements = 0

foreach ($file in $files) {
    $content = Get-Content $file -Raw -Encoding UTF8
    $originalContent = $content
    
    $content = $content -replace 'Zabbix agent', 'TAA agent'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file -Value $content -Encoding UTF8 -NoNewline
        $replacements = ([regex]::Matches($originalContent, 'Zabbix agent')).Count
        $totalReplacements += $replacements
        Write-Host "  OK $($file.Name): $replacements replacements"
    }
}

Write-Host ""
Write-Host "Total replacements: $totalReplacements (Zabbix agent to TAA agent)"
