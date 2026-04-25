param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateNotNullOrEmpty()]
  [string] $FunctionName,

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string] $ProjectRef = "uogaveubabnsskfwftui"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $projectRoot ".env.local"

function Import-LocalEnv {
  param([string] $Path)

  if (-not (Test-Path $Path)) {
    return
  }

  Get-Content $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith("#") -or -not $line.Contains("=")) {
      return
    }

    $parts = $line.Split("=", 2)
    $name = $parts[0].Trim()
    $value = $parts[1].Trim()
    if ($name.Length -gt 0 -and -not [Environment]::GetEnvironmentVariable($name, "Process")) {
      Set-Item -Path "Env:$name" -Value $value
    }
  }
}

Import-LocalEnv -Path $envPath

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_ACCESS_TOKEN)) {
  throw "SUPABASE_ACCESS_TOKEN is missing. Add it to .env.local or set it in the current shell."
}

Push-Location $projectRoot
try {
  & npx --yes supabase functions deploy $FunctionName `
    --project-ref $ProjectRef `
    --use-api
}
finally {
  Pop-Location
}
