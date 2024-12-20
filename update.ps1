
# unknown = {code, title, series}[]
# series = {code, name, albums = {code, title}[]}[]

# Get-Url
. "$PSScriptRoot/Get-Url.ps1"
# Get-Series
. "$PSScriptRoot/Get-Series.ps1"
# Get-Albums
. "$PSScriptRoot/Get-Albums.ps1"
# Get-Name
. "$PSScriptRoot/Get-Name.ps1"
# set delay in milliseconds
$delay = 100
# excluded series
$exclSeries = @(
    "SRI0000040622"
)
# excluded albums
$exclAlbums = @(
    # SRI0000020252
    "RJ226470", "RJ234748", "RJ243180", "RJ253788", "RJ264095", "RJ270613", "RJ285211", "RJ296718", "RJ311537"
    # SRI0000025177
    "RJ383035"
    # SRI0000030712
    "RJ352446", "RJ394256", "RJ01018608", "RJ01018618", "RJ01190092", "RJ01268906"
)

# fine all directories that match "[code] title" recursively
$albums = (Get-ChildItem -Path "$PSScriptRoot/.." -Filter "[*]*" -Directory -Recurse).Name
# parse albums as {code, title, series = "unknown"}[]
$unknown = @()
foreach ($album in $albums) {
    $groups = ($album | Select-String -Pattern "\[(\w+)\]\s?(.*)").Matches.Groups
    $unknown += @{code = $groups[1].Value; title = $groups[2].Value; series = "unknown"}
}
# get series for all albums in unknown
# from history
$markdown = "$PSScriptRoot/update.md"
if (Test-Path $markdown) {
    # parse history as @(series, album0, album1, ...)[]
    $history = @()
    foreach ($line in Get-Content $markdown) {
        if ($line -eq "" -or $line -eq "<div style='display:none'>") {
            continue
        } elseif ($line -eq "</div>") {
            break
        } else {
            $history += , (-split $line)
        }
    }
    # get series from history
    foreach ($album in $unknown) {
        $album.series = ($history | Where-Object -FilterScript {$_ -contains $album.code}) | Select-Object -First 1
        if ($album.series.Length -le 0) {
            $album.series = "unknown"
        }
    }
}
# from remote
foreach ($album in $unknown | Where-Object -FilterScript {$_.series -eq "unknown"}) {
    $album.series = Get-Series $album.code
    Start-Sleep -Milliseconds $delay
}
# sort unknown by series & code
$unknown = $unknown | Sort-Object -Property {$_.series}, {$_.code.Length}, {$_.code}
# collect all series
$series = @()
foreach ($serie in $unknown.series | Select-Object -Unique) {
    if ($serie -eq "error/web" -or $serie -eq "single") { # error/web & single
        $series += @{code = $serie; name = $serie; albums = $unknown | Where-Object -FilterScript {$_.series -eq $serie} | Select-Object -Property code, title}
    } elseif ($serie -in $exclSeries) { # excluded series
        $series += @{code = $serie; name = "~~$(Get-Name $serie)~~"; albums = $unknown | Where-Object -FilterScript {$_.series -eq $serie} | Select-Object -Property code, title}
    } else { # series
        # append series, get name & albums from remote
        $series += Get-Albums $serie
        Start-Sleep -Milliseconds $delay
        # mark archived albums
        foreach ($album in $series[-1].albums) {
            if ($album.code -notin $unknown.code) {
                if ($album.code -in $exclAlbums) {
                    $album.title = "~~$($album.title)~~"
                } else {
                    $album.title = "**$($album.title)**"
                }
            }
        }
    }
}
# write history
"" | Out-File $markdown
"<div style='display:none'>" | Out-File $markdown -Append
foreach ($serie in $series | Where-Object -FilterScript {$_.code -ne "error"}) {
    $string = "$($serie.code)"
    foreach ($album in $serie.albums) {
        $string += " $($album.code)"
    }
    $string | Out-File $markdown -Append
}
"</div>`n" | Out-File $markdown -Append
# write series
foreach ($serie in $series) {
    # disclose details if unarchived albums in series
    if ("**" -in $serie.albums.title.substring(0, 2)) {
        $details = "<p><details open>"
    } else {
        $details = "<p><details>"
    }
    # remove ^~~ & ~~$ in summary series name
    $summary = $serie.name
    if ($summary.substring(0, 2) -eq "~~") {
        $summary = $summary.substring(2, $summary.length - 4)
    }
    $summary = "<summary><b>$summary</b></summary>"
    # details
    "$details$summary`n" | Out-File $markdown -Append
    # link for series
    if ($serie.code -eq "error/web" -or $serie.code -eq "single") { # error/web & single
        $a = " "
    } else { # series
        $a = "<a href='$(Get-Url "series" $serie.code)' target='_blank'>$($serie.code)</a>"
    }
    # table
    # series
    "|$a|$($serie.name)|search|" | Out-File $markdown -Append
    # separator
    "|-|-|:-:|" | Out-File $markdown -Append
    foreach ($album in $serie.albums) {
        # albums
        "|<a href='$(Get-Url "album" $album.code)' target='_blank'>$($album.code)</a>|$($album.title)|<a href='$(Get-Url "asmr" $album.code)' target='_blank'>:mag:</a>|" | Out-File $markdown -Append
    }
    # details end
    "</details></p>`n" | Out-File $markdown -Append
}
Start-Process gvim "$markdown -c `"normal ,mt`""
