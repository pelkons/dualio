$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $projectRoot ".env.local"
$flutter = "C:\Users\plkns\dev\flutter\bin\flutter.bat"

if (-not (Test-Path $envPath)) {
  throw ".env.local was not found at $envPath"
}

$values = @{}
Get-Content $envPath | ForEach-Object {
  $line = $_.Trim()
  if ($line.Length -eq 0 -or $line.StartsWith("#")) {
    return
  }

  $parts = $line.Split("=", 2)
  if ($parts.Count -eq 2) {
    $values[$parts[0]] = $parts[1]
  }
}

foreach ($required in @("SUPABASE_URL", "SUPABASE_ANON_KEY")) {
  if (-not $values.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($values[$required])) {
    throw "$required is missing in .env.local"
  }
}

Push-Location $projectRoot
try {
  & $flutter run `
    --dart-define="SUPABASE_URL=$($values["SUPABASE_URL"])" `
    --dart-define="SUPABASE_ANON_KEY=$($values["SUPABASE_ANON_KEY"])" `
    @args
}
finally {
  Pop-Location
}
