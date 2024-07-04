function Get-Series([string]$album) {
    # web request
    $url = Get-Url "album" $album
    $response = Invoke-WebRequest -Uri $url
    if ($response.StatusCode -ne 200) { # web error
        return "error/web"
    } # match series code                                                                                                   $series.code  $series.name
    $match_es = ($response.Content | Select-String -Pattern "<tr>\s*<th>\s*シリーズ名\s*</th>\s*<td>\s*<a href=`".*/title_id/(\w+)/.*`">\s*(.+)\s*</a>\s*</td>\s*</tr>").Matches
    if ($match_es.Success) { # series code
        return $match_es.Groups[1].Value
    } else { # single
        return "single"
    }
}
