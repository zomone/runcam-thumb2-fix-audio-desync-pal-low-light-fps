# Patcheur du firmware RunCam Thumb 2 V1.2.2 (NON TESTE / UNTESTED)
# Applique au Thumb2.bin officiel les deux corrections de autoexec.ash :
#  - table PAL : 22 lignes 50000/1001 -> 50000/1000 (son synchro)
#  - slow shutter toujours desactive (pas de chute de fps dans le noir)
# puis recalcule les CRC connus. Le fichier officiel n'est pas modifie.

param([string] $Source)

$ErrorActionPreference = 'Stop'
$ShaOfficiel = '97C51BAF0607181E9722A0C58A92CC02591641D95B1F3FE228458B5B638F36E6'
$ShaAttendu  = '4EDF554D607CCE33111CD000415DC5F2B3CD3AACD86CFBC6DC0E034D2528D0C8'

if (-not $Source) { $Source = Join-Path $PSScriptRoot 'Thumb2.bin' }
if (-not (Test-Path $Source)) {
    Write-Host "Thumb2.bin introuvable / not found : $Source" -ForegroundColor Red
    Write-Host "Glisse le Thumb2.bin officiel V1.2.2 sur PATCHER.bat / Drag the official V1.2.2 Thumb2.bin onto PATCHER.bat"
    exit 1
}

Add-Type -TypeDefinition @'
public static class Crc32 {
    static readonly uint[] T = Make();
    static uint[] Make() {
        var t = new uint[256];
        for (uint i = 0; i < 256; i++) {
            uint c = i;
            for (int k = 0; k < 8; k++) c = (c & 1) != 0 ? 0xEDB88320u ^ (c >> 1) : c >> 1;
            t[i] = c;
        }
        return t;
    }
    public static uint Of(byte[] b, int start, int end) {
        uint c = 0xFFFFFFFFu;
        for (int i = start; i < end; i++) c = T[(c ^ b[i]) & 0xFF] ^ (c >> 8);
        return c ^ 0xFFFFFFFFu;
    }
}
'@

function Sha256($bytes) {
    $h = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return ([BitConverter]::ToString($h) -replace '-', '')
}
function Get-U32($b, $o) { return [BitConverter]::ToUInt32($b, $o) }
function Set-U32($b, $o, [uint32] $v) { [BitConverter]::GetBytes($v).CopyTo($b, $o) }

$d = [IO.File]::ReadAllBytes((Resolve-Path $Source))
if ((Sha256 $d) -ne $ShaOfficiel) {
    Write-Host "Ce n'est pas le Thumb2.bin officiel V1.2.2 : arret, rien n'est modifie." -ForegroundColor Red
    Write-Host "This is not the official V1.2.2 Thumb2.bin: stopping, nothing changed." -ForegroundColor Red
    exit 1
}
Write-Host "Thumb2.bin officiel V1.2.2 reconnu / official V1.2.2 recognised." -ForegroundColor Green

# adresses RAM (section 1 chargee a 0x20000, donnees a 0x330 dans le fichier)
$pal = 0xae945c,0xae9a8c,0xae9aa4,0xae9abc,0xae9aec,0xae9b04,0xae9b34,0xae9b4c,0xae9bdc,0xae9c3c,0xae9c9c,
       0xae9ccc,0xae9cfc,0xae9d14,0xae9d44,0xae9d5c,0xae9d74,0xae9d8c,0xae9e4c,0xae9e64,0xae9e7c,0xae9e94
foreach ($a in $pal) {
    $o = $a - 0x20000 + 0x330
    if ((Get-U32 $d $o) -ne 1001) { throw "valeur inattendue a $('0x{0:x}' -f $a)" }
    Set-U32 $d $o 1000
}
$o = 0x112100 - 0x20000 + 0x330
if ((Get-U32 $d $o) -ne [Convert]::ToUInt32('C3A03001', 16)) { throw 'instruction slow shutter inattendue' }
Set-U32 $d $o ([Convert]::ToUInt32('C3A03000', 16))

# CRC : section 1, table des CRC cumules, CRC global
$hs = 0x230, 0xb3e9d0, 0xee92d0, 0x1952bd0, 0x1ec2130, 0x2908230
$ends = @($hs[1..5]) + $d.Length
$len1 = Get-U32 $d (0x230 + 12)
Set-U32 $d 0x230 ([Crc32]::Of($d, 0x330, 0x330 + $len1))
for ($i = 0; $i -lt 5; $i++) { Set-U32 $d (0x34 + 8 * $i) ([uint32]::MaxValue -bxor [Crc32]::Of($d, 0x230, $ends[$i])) }
$c = [Crc32]::Of($d, 0x230, $d.Length)
Set-U32 $d 0x24 $c
Set-U32 $d 0x5C ([uint32]::MaxValue -bxor $c)

if ((Sha256 $d) -ne $ShaAttendu) { throw 'Resultat inattendu : fichier non ecrit / unexpected result: file not written' }
$dest = Join-Path (Split-Path (Resolve-Path $Source)) 'Thumb2_V1.2.2_patched_UNTESTED.bin'
[IO.File]::WriteAllBytes($dest, $d)
Write-Host ""
Write-Host "OK -> $dest" -ForegroundColor Green
Write-Host "JAMAIS TESTE. Le flasher est a tes risques. / NEVER TESTED. Flash at your own risk." -ForegroundColor Yellow
