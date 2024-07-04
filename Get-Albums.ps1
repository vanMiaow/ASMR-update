function Get-Albums([string]$serie) {
    # init
    $series = @{code = $serie; name = "unknown"; albums = @()}
    $delay = 100
    $page = 0
    while ($true) {
        $page++
        # web request
        $url = Get-Url "series" $series.code $page
        $response = Invoke-WebRequest -Uri $url
        if ($response.StatusCode -ne 200) { # web error
            $series.name = "error/web"
            return $series
        }
        if ($series.name -eq "unknown") { # match series name                                          $series.code                               $series.name
            $match_es = ($response.Content | Select-String -Pattern "<li.*>\s*<a.*\s*href=`".*/title_id/(\w+)/.*`">\s*<span itemprop=`"name`">\s*「(.+)」シリーズ\s*</span>\s*</a>\s*<meta itemprop=`"position`" content=`"4`">\s*</li>").Matches
            if ($match_es.Success) { # series name
                $series.name = $match_es.Groups[2].Value
            } else { # error
                $series.name = "error/name"
                return $series
            }
        } # match album code & title                                                                                                                                             $album.code              $album.title
        $match_es = ($response.Content | Select-String -Pattern "<dd class=`"work_name`"><div class=`"icon_wrap`"></div><div class=`"multiline_truncate`"><a href=`".*/product_id/(\w+).html`" title=`".*`">(.+)</a></div></dd>" -AllMatches).Matches
        if ($match_es.Success) {
            foreach ( $ma_tch in $match_es ) { # append album
                $series.albums += @{code = $ma_tch.Groups[1].Value; title = $ma_tch.Groups[2].Value}
            }
        } else { # error
            $series.name = "error/albums"
            return $series
        } # check next page
        $match_es = ($response.Content | Select-String -Pattern "<li><a href=`".*`" data-value=`".*`">次へ</a></li>").Matches
        if (!($match_es.Success)) {
            break
        } # delay
        Start-Sleep -Milliseconds $delay
    }
    return $series
}
