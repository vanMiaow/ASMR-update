function Get-Name([string]$serie) {
    # web request
    $url = Get-Url "series" $serie
    $response = Invoke-WebRequest -Uri $url
    if ($response.StatusCode -ne 200) { # web error
        return "error/web"
    }
    # match series name                                                                        $series.code                               $series.name
    $match_es = ($response.Content | Select-String -Pattern "<li.*>\s*<a.*\s*href=`".*/title_id/(\w+)/.*`">\s*<span itemprop=`"name`">\s*「(.+)」シリーズ\s*</span>\s*</a>\s*<meta itemprop=`"position`" content=`"4`">\s*</li>").Matches
    if ($match_es.Success) { # series name
        return $match_es.Groups[2].Value
    } else { # error
        return "error/name"
    }
}
