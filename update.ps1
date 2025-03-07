
# asmr = [{code, title, excl, albums = [{code, title, arch, excl}]}]

# paths
. "$PSScriptRoot/exclude.ps1"
. "$PSScriptRoot/function.ps1"
$lib  = "$PSScriptRoot/.."
$json = "$PSScriptRoot/asmr.json"
$md   = "$PSScriptRoot/asmr.md"

if (Test-Path $json) {
# if json does exist, load database
    echo "Load database."
    $asmr = Get-Content $json | ConvertFrom-Json -AsHashtable
} else {
# if json does not exist, initialize database
    echo "Initialize database."
    $asmr = @()
}
# mark excluded series
echo "Mark excluded series."
foreach ($series in $asmr) {
    $series.excl = $series.code -in $exclSeries
}
# get local albums
echo "Get loacl albums."
$local = (Get-ChildItem $lib "[*]*" -Directory -Recurse).Name
$local = @($local | ForEach-Object {$_.Substring(1, $_.IndexOf(']') - 1)})

# process new albums
echo "Process new albums."
foreach ($code in $local) {
    $new = $true
    foreach ($series in $asmr) {
        if ($code -in $series.albums.code) {
        # if found in database, do nothing
            $new = $false
            break
        }
    }
    if ($new) {
    # if new, process
        # get series of album
        $series = Get-Series $code
        # mark excluded series
        $series.excl = $series.code -in $exclSeries
        # echo
        echo "New album [$code] add to$(($series.code -in $asmr.code)?'':' new') series [$($series.code)]."
        if ($series.code -notin $asmr.code) {
        # if series not in database, append
            $asmr += $series
        }
        if ($series.excl) {
        # if series excluded, get album and append
            $album = Get-Album $code
            # do not append if error
            if ($album.title -ne "Get-Album.Error.Title") {
                foreach ($series_ in $asmr) {
                    if ($series_.code -eq $series.code) {
                        $series_.albums += $album
                    }
                }
            }
        }
    }
}

# update series
foreach ($series in $asmr) {
    if (-not $series.excl) {
    # get albums of series, skip excluded
        echo "Update series [$($series.code)]."
        $series.albums = Get-Albums $series.code
    }
    # mark archived and excluded albums
    foreach ($album in $series.albums) {
        $album.arch = $album.code -in $local
        $album.excl = $album.code -in $exclAlbums
    }
    if ($series.excl) {
    # if series excluded, remove unarchived albums
        echo "Remove unarchived albums in series [$($series.code)]."
        $series.albums = @($series.albums | Where-Object {$_.arch})
    }
    # sort albums
    $series.albums = @($series.albums | Sort-Object {$_.code.Length}, {$_.code})
}
# remove unarchived series
echo "Remove unarchived series."
$asmr = @($asmr | Where-Object {$_.albums.Count -and $_.albums.arch -contains $true})
# sort series
echo "Sort series."
$asmr = @($asmr | Sort-Object {$_.code})

# save json
echo "Save json."
$asmr | ConvertTo-Json -Depth 3 | Out-File $json
# convert to markdown
echo "Convert to markdown."
$buffer = @()
foreach ($series in $asmr) {
  # details
    # count unarchived albums
    $count = @($series.albums | Where-Object {-not ($_.arch -or $_.excl)}).Count
    # if any unarchived, disclose details
    $buffer += "<p><details$(($count)?' open':'')><summary><b>$($series.title)</b></summary>`n"
  # header
    if ($series.excl) {
    # if excluded, strike through series title
        $title = "~~$($series.title)~~"
    } else {
    # otherwise no modification on series title
        $title = $series.title
    }
    if ($series.code -eq "SINGLE") {
    # if single, omit series link
        $link = ""
    } else {
    # otherwise get series link
        $link = "<a href='$(Get-DLsite $series.code)' target='_blank'>$($series.code)</a>"
    }
    $buffer += "|$link|$title|search|`n|-|-|:-:|"
  # data
    foreach ($album in $series.albums) {
        if ($album.arch) {
            if ($album.excl) {
            # if archived and excluded, strike through album title
                $title = "~~$($album.title)~~"
            } else {
            # if archived and not excluded, no modification on album title
                $title = $album.title
            }
        } else {
            if ($album.excl) {
            # if not archived and excluded, omit album
                $title = ""
            } else {
            # if not archived and not excluded, bold album title
                $title = "**$($album.title)**"
            }
        }
        # get album link
        $link = "<a href='$(Get-DLsite $album.code)' target='_blank'>$($album.code)</a>"
        # get search link
        $search = "<a href='$(Get-ASMR $album.code)' target='_blank'>:mag:</a>"
        if ($title) {
            $buffer += "|$link|$title|$search|"
        }
    }
  # details end
    $buffer += "</details></p>`n"
}
# save markdown
echo "Save Markdown."
$buffer | Out-File $md
# open markdown
Start-Process gvim "$md -c `"normal ,mt`""

return

