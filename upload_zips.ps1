$base = "C:\Users\japodaca15\projectsClaude\mauve-classroom\zips"
$panels = @("saureus","paeruginosa","ecoli","salmonella","epidermidis","acinetobacter")

foreach ($panel in $panels) {
    $zip = "$base\${panel}_classroom_dataset.zip"
    Write-Host "Uploading $panel ($zip)..."
    gh release upload v2.4.7 "$zip" --repo cryptic-prophage/mauve-classroom --clobber
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK"
    } else {
        Write-Host "  FAILED (exit $LASTEXITCODE)"
    }
}
Write-Host "Done."
