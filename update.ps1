
# album = { code, title, circle = { code, name }, series = { code, title }, artist, cover, trans }
# series = { code, title, circle = { code, name }, albums = [{ code, title, cover }] }
# asmr = { "code" = album }

param(
    [Parameter(ParameterSetName = "Update")]
    [switch]$Init,
    [Parameter(ParameterSetName = "Update")]
    [switch]$Lyrics,
    [Parameter(ParameterSetName = "View", Mandatory)]
    [switch]$View
)

# paths
. "$PSScriptRoot/exclude.ps1"
. "$PSScriptRoot/function.ps1"
. "$PSScriptRoot/html.ps1"
$lib  = "$PSScriptRoot/.."
$json = "$PSScriptRoot/asmr.json"
$md   = "$PSScriptRoot/asmr.md"

#---- View ---->

if ($View) {
    if (Test-Path $md) {
        Start-Process nvim "$md +normal,v" -Wait -NoNewWindow
    } else {
        echo "Markdown not found."
    }
    return
}

#---- Update ---->

# init asmr
if ($Init -or -not (Test-Path $json)) {
    echo "Initialize database."
    $asmr = @{}
} else {
    echo "Load database."
    $asmr = Get-Content $json | ConvertFrom-Json -AsHashtable
}

# get local
echo "Get loacl albums."
$localDir = Get-ChildItem $lib "[*]*" -Directory -Recurse
$local = $localDir.Name | ForEach-Object { if ($_ -match '\[(\w+)\].+') { $matches[1] } } | Sort-Object { $_.Length }, { $_ }

# get lyrics
echo "Get local lyrics."
$lrcDir = $localDir | Where-Object { Get-ChildItem -LiteralPath $_.FullName "*.lrc" -Recurse }
$lrc = $lrcDir.Name | ForEach-Object { if ($_ -match '\[(\w+)\].+') { $matches[1] } }

# update albums
foreach ($code in $local) {
    if (-not $asmr.$code) {
        # new album
        $asmr.$code = Get-Album $code
        echo "New album: [$code] $($asmr.$code.title)"
    } elseif ($Lyrics) {
        # update lyrics
        if (($code -notin $lrc) -and (-not $asmr.$code.trans)) {
            $asmr.$code = Get-Album $code
            echo "Check lyrics: [$code] $($asmr.$code.title)"
        }
    }
}

# save json
echo "Save json."
$asmr | ConvertTo-Json | Out-File $json

# update series
$series = @{}
foreach ($code in $asmr.Values.series.code | Sort-Object -Unique) {
    if ($code -in $exclSeries) {
        # excluded series, collect form local
        $series.$code = @{ code = $code }
        $albums = $asmr.Values | Where-Object { $_.series.code -eq $code } | Sort-Object { $_.code.Length }, { $_.code }
        $ref = $albums | Select-Object -First 1
        # title
        $series.$code.title = $ref.series.title
        # circle
        if ($code -eq "SINGLE") {
            $series.$code.circle = @{ code = ""; name = "" }
        } else {
            $series.$code.circle = $ref.circle
        }
        # albums
        $series.$code.albums = $albums | ForEach-Object { @{ code = $_.code; title = $_.title; cover = $_.cover } }
        echo "Exclude series: [$code] $($series.$code.title)"
    } else {
        # normal series, fetch from remote
        $series.$code = Get-Series $code
        echo "Update series: [$code] $($series.$code.title)"
    }
}

# convert to markdown
echo "Convert to markdown."
$buffer = Html-Style
# for each series, sorted by circle name
foreach ($code in $series.Values.code | Sort-Object { $series.$_.circle.name }) {
    # open details by default or not
    $open = $false
    # array of albums, string[][]
    # each string[] is a table data representing an album
    $albums = @()
    # for each album
    foreach ($album in $series.$code.albums) {
        # skip excluded albums
        if ($album.code -in $exclAlbums) { continue }
        # determine album type, add and translate will open the details by default
        if ($album.code -notin $local) {
            # -local
            $open = $true
            $type = "add"
        } elseif ($Lyrics -and $album.code -notin $lrc -and $asmr.($album.code).trans) {
            # +local, -lrc and +trans
            $open = $true
            $type = "translate"
        } else {
            # +local, +lrc or -trans
            $type = "search"
        }
        # append album table data
        $albums += , (Html-Album $album $type)
    }
    # arrange albums in rows
    $buffer += Html-Series $series.$code $open $albums
}

# save markdown
echo "Save markdown."
$buffer | Out-File $md

# view markdown
Start-Process nvim "$md +normal,v" -Wait -NoNewWindow

return

