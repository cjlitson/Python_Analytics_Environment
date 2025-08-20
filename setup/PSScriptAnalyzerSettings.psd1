@{
  # Temporarily suppress a few noisy style rules we don't care about
  ExcludeRules = @(
    'PSAvoidUsingWriteHost',          # we'll migrate gradually to Write-Information
    'PSUseBOMForUnicodeEncodedFile'   # harmless for our scripts; we can add BOM later
  )
}
