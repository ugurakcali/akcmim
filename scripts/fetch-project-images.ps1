$ErrorActionPreference = 'Stop'

# Paths
$projDir = 'c:\Users\UGUR\Desktop\akc-kentsel'
$imgDir  = Join-Path $projDir 'assets\img\projects'

if (!(Test-Path $imgDir)) {
  New-Item -ItemType Directory -Path $imgDir -Force | Out-Null
}

# Fetch page
$resp = Invoke-WebRequest -UseBasicParsing -Uri 'https://www.akcmim.com/projelerimiz'

# Collect image URLs (prefer googleusercontent)
$urls = @()
if ($resp.Images) {
  $urls = $resp.Images |
    Where-Object { $_.src -match '^https://lh\d+\.googleusercontent\.com/' } |
    Select-Object -ExpandProperty src -Unique
}

if (-not $urls -or $urls.Count -lt 9) {
  $pattern = "https://lh\d+\.googleusercontent\.com/[^\s`"')]+"
  $matches = [regex]::Matches($resp.Content, $pattern)
  $urls = ($matches | ForEach-Object { $_.Value } | Select-Object -Unique)
}

$names = @(
  'bayram-apt','dostlar-sitesi','huzur-sitesi','papatya-evleri',
  'tahir-turan-sitesi','bayraktar-apt','uslu-apt','kayalar-apt','yakut-apt'
)

$take = [Math]::Min($urls.Count, $names.Count)

for ($i = 0; $i -lt $take; $i++) {
  $out = Join-Path $imgDir ($names[$i] + '.jpg')
  try {
    Invoke-WebRequest -UseBasicParsing -Uri $urls[$i] -OutFile $out
  } catch {
    Write-Host ("Download failed: " + $urls[$i])
  }
}

# Update index.html images inside the projeler section only
$indexPath = Join-Path $projDir 'index.html'
$html = Get-Content -Raw -Path $indexPath
$secMatch = [regex]::Match($html,'(?s)<section id="projeler".*?</section>')
if (-not $secMatch.Success) {
  Write-Host 'Projeler bölümü bulunamadı.'
  exit 0
}
$section = $secMatch.Value
$imgPattern = '(?s)(<img\s+[^>]*?src=")([^"]*)(")'

for ($i = 0; $i -lt $take; $i++) {
  $newSrc = 'assets/img/projects/' + $names[$i] + '.jpg'
  $replacement = "`$1$newSrc`$3"
  $section = [regex]::Replace($section, $imgPattern, $replacement, 1)
}

$newHtml = $html.Substring(0, $secMatch.Index) + $section + $html.Substring($secMatch.Index + $secMatch.Length)
Set-Content -Path $indexPath -Value $newHtml -Encoding UTF8

Write-Host ("Updated $take images")
