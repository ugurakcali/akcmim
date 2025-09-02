$ErrorActionPreference = 'Stop'

# Paths
$projDir = 'c:\Users\UGUR\Desktop\akc-kentsel'
$imgSrc = Join-Path $projDir 'projeler_files'
$imgDst = Join-Path $projDir 'assets\img\projects'

if (!(Test-Path $imgDst)) {
  New-Item -ItemType Directory -Path $imgDst -Force | Out-Null
}

# 1) Clean destination folder
Get-ChildItem -Path $imgDst -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# Helper: resolve first file by wildcard pattern safely
function Resolve-First($pattern) {
  $file = Get-ChildItem -LiteralPath $imgSrc -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern } | Select-Object -First 1
  if ($null -ne $file) { return $file.FullName } else { return $null }
}

# 2) Build mapping using robust wildcard matches (handles Turkish chars/spaces)
$map = @(
  @{ Name='bayram-apt';          Source=(Resolve-First 'WhatsApp*17.17.41*') },
  @{ Name='dostlar-sitesi';      Source=(Resolve-First '25063_3.*') },
  @{ Name='huzur-sitesi';        Source=(Resolve-First '25067_3.*') },
  @{ Name='papatya-evleri';      Source=(Resolve-First '25073_5.*') },
  @{ Name='tahir-turan-sitesi';  Source=(Resolve-First 'WhatsApp*14.03.30*') },
  @{ Name='bayraktar-apt';       Source=(Resolve-First '1493_11.*') },
  @{ Name='uslu-apt';            Source=(Resolve-First '1743_20.*') },
  @{ Name='kayalar-apt';         Source=(Resolve-First '10248_6.*') },
  @{ Name='yakut-apt';           Source=(Resolve-First '*145911*.png') }
)

# 3) Copy files into destination with standardized names (keep original extension)
$finalList = @()
foreach ($item in $map) {
  $src = $item.Source
  if ($null -ne $src -and (Test-Path $src)) {
    $ext = [IO.Path]::GetExtension($src)
    $dst = Join-Path $imgDst ($item.Name + $ext)
    Copy-Item -Path $src -Destination $dst -Force
    $finalList += @{ Name=$item.Name; Ext=$ext }
  }
}

if ($finalList.Count -eq 0) { Write-Host 'No images copied; check projeler_files.'; exit 0 }

# 4) Update only the first N images in projeler section of index.html
$indexPath = Join-Path $projDir 'index.html'
# Read HTML
$html = Get-Content -Raw -Path $indexPath

$secMatch = [regex]::Match($html,'(?s)<section id=\"projeler\".*?</section>')
if (-not $secMatch.Success) { Write-Host 'Projeler bölümü bulunamadı.'; exit 0 }
$section = $secMatch.Value

# Replace images by article order to avoid repeated first-match replacements
$desiredOrder = @(
  'assets/img/projects/bayram-apt.jpg',
  'assets/img/projects/dostlar-sitesi.png',
  'assets/img/projects/huzur-sitesi.png',
  'assets/img/projects/papatya-evleri.png',
  'assets/img/projects/tahir-turan-sitesi.jpg',
  'assets/img/projects/bayraktar-apt.png',
  'assets/img/projects/uslu-apt.png',
  'assets/img/projects/kayalar-apt.png',
  'assets/img/projects/yakut-apt.png'
)

$articlePattern = '(?s)(<article\s+class=\"project\".*?<\/article>)'
$articles = [regex]::Matches($section, $articlePattern)
for ($i = 0; $i -lt [Math]::Min($articles.Count, $desiredOrder.Count); $i++) {
  $article = $articles[$i].Groups[1].Value
  $newSrc = $desiredOrder[$i]
  $updatedArticle = [regex]::Replace($article, '(?s)(<img\s+[^>]*?src=\")[^\"]*(\")', "`$1$newSrc`$2", 1)
  # Replace the specific article block in section
  $section = $section.Substring(0, $articles[$i].Index) + $updatedArticle + $section.Substring($articles[$i].Index + $articles[$i].Length)
  # Adjust subsequent match indices by re-matching after each replacement
  $articles = [regex]::Matches($section, $articlePattern)
}

$newHtml = $html.Substring(0, $secMatch.Index) + $section + $html.Substring($secMatch.Index + $secMatch.Length)
Set-Content -Path $indexPath -Value $newHtml -Encoding UTF8

Write-Host ("Updated " + $finalList.Count + ' images from projeler_files (wildcards)')
