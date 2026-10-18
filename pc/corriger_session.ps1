# Corrige la derive son/image de la RunCam Thumb 2 (mode 2.7K "60 fps" en PAL).
# Le capteur filme a 50,000 images/s mais le fichier annonce 49,95 images/s :
# l'image prend 1 ms de retard par seconde, d'un rush a l'autre.
# Ce script recolle chaque seance (rushs coupes a 4 Go) en un seul fichier,
# avec l'image remise a 50 images/s. Aucun reencodage, aucune perte de qualite.

param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Chemins)

$ErrorActionPreference = 'Stop'
$ff = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
$fp = (Get-Command ffprobe -ErrorAction SilentlyContinue).Source
if (-not $ff) {
    $bin = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bin) { $ff = $bin.FullName; $fp = Join-Path $bin.DirectoryName 'ffprobe.exe' }
}
if (-not $ff) { Write-Host "ffmpeg introuvable." -ForegroundColor Red; exit 1 }

# fichiers MP4 donnes (ou contenus dans les dossiers donnes)
$files = @()
foreach ($c in $Chemins) {
    if (Test-Path $c -PathType Container) { $files += Get-ChildItem $c -Filter *.MP4 }
    elseif ($c -match '\.mp4$') { $files += Get-Item $c }
}
$files = $files | Where-Object { $_.Name -notmatch '_synchro' } | Sort-Object Name -Unique
if (-not $files) { Write-Host "Glisse un dossier DCIM\100MEDIA ou des fichiers MP4 sur corriger_session.bat"; exit 1 }

$out = Join-Path ([Environment]::GetFolderPath('MyVideos')) 'RunCam_synchro'
New-Item -ItemType Directory -Force $out | Out-Null

# regroupe en seances : un rush continue la seance si le precedent a ete coupe a ~4 Go
$sessions = @(); $cur = @()
foreach ($f in $files) {
    $prev = $cur | Select-Object -Last 1
    if ($prev -and ($prev.Length -lt 3.8e9)) { $sessions += , $cur; $cur = @() }
    $cur += $f
}
if ($cur) { $sessions += , $cur }

# affiche les rushs numerotes et laisse choisir les seances
function Duree($f) {
    if (-not $fp) { return '' }
    $d = & $fp -v error -show_entries format=duration -of csv=p=0 $f.FullName 2>$null
    if (-not $d) { return '' }
    $t = [TimeSpan]::FromSeconds([double]::Parse($d, [Globalization.CultureInfo]::InvariantCulture))
    return '{0}:{1:00}' -f [int][math]::Floor($t.TotalMinutes), $t.Seconds
}
Write-Host ""
Write-Host "Seances detectees (un rush coupe a 4 Go continue la seance) :" -ForegroundColor Cyan
$n = 0; $k = 0
foreach ($s in $sessions) {
    $k++
    Write-Host "  Seance $k"
    foreach ($f in $s) {
        $n++
        Write-Host ("    [{0}] {1}  {2:N1} Go  {3}" -f $n, $f.Name, ($f.Length / 1e9), (Duree $f))
    }
}
Write-Host ""
Write-Host "Entree = garder ces seances."
Write-Host "Sinon tape tes seances separees par des espaces, ex : 1-3 4 5-7"
Write-Host "(1-3 = rushs 1 a 3 recolles ensemble ; un rush non cite est ignore)"
while ($true) {
    $rep = (Read-Host "Choix").Trim()
    if (-not $rep) { break }
    $choix = @(); $ok = $true
    foreach ($tok in ($rep -split '\s+')) {
        if ($tok -match '^(\d+)(?:-(\d+))?$') {
            $a = [int]$Matches[1]; $b = if ($Matches[2]) { [int]$Matches[2] } else { $a }
            if ($a -lt 1 -or $b -gt $files.Count -or $a -gt $b) { $ok = $false; break }
            $choix += , @($files[($a - 1)..($b - 1)])
        } else { $ok = $false; break }
    }
    if ($ok) { $sessions = $choix; break }
    Write-Host "Je n'ai pas compris, numeros de 1 a $($files.Count), ex : 1-3 4 5-7" -ForegroundColor Yellow
}

foreach ($s in $sessions) {
    $first = [IO.Path]::GetFileNameWithoutExtension($s[0].Name)
    $last = [IO.Path]::GetFileNameWithoutExtension($s[-1].Name)
    $name = if ($s.Count -gt 1) { "${first}_a_${last}_synchro.mp4" } else { "${first}_synchro.mp4" }
    $dest = Join-Path $out $name
    Write-Host ""
    Write-Host "Seance : $($s.Name -join ', ')" -ForegroundColor Cyan
    $list = Join-Path $env:TEMP ("runcam_concat_" + [guid]::NewGuid().ToString('N') + ".txt")
    $lines = $s | ForEach-Object { "file '" + ($_.FullName -replace "'", "'\''") + "'" }
    [IO.File]::WriteAllLines($list, $lines)
    # entree 0 : image, horodatage x 1000/1001 (49,95 -> 50 images/s) ; entree 1 : son tel quel
    & $ff -v error -stats -y -itsscale 0.999000999000999 -f concat -safe 0 -i $list `
        -f concat -safe 0 -i $list -map 0:v:0 -map 1:a:0 -c copy -movflags +faststart $dest
    $ok = $LASTEXITCODE -eq 0
    Remove-Item $list -ErrorAction SilentlyContinue
    if ($ok) { Write-Host "OK -> $dest" -ForegroundColor Green } else { Write-Host "ECHEC pour cette seance" -ForegroundColor Red }
}
Write-Host ""
Write-Host "Fichiers corriges dans : $out"
