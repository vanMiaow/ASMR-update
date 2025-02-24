
# Get-DLsite
function Get-DLsite([string]$code, [int]$page = 1) {
    $prefix = $code.Substring(0, 2)
    if ($prefix -eq "BJ" -or $prefix -eq "TI") { # BJ
        $type = "books"
    }
    if ($prefix -eq "RJ" -or $prefix -eq "SR") { # RJ
        $type = "maniax"
    }
    if ($prefix -eq "BJ" -or $prefix -eq "RJ") { # album
        return "https://www.dlsite.com/$type/work/=/product_id/$code.html"
    }
    if ($prefix -eq "TI" -or $prefix -eq "SR") { # series
        return "https://www.dlsite.com/$type/fsr/=/title_id/$code/order/release/per_page/100/page/$page"
    }
    return "Get-DLsite.Error.Prefix" # error
}

# Get-ASMR
function Get-ASMR([string]$keyword) {
    return "https://asmr.one/works?keyword=$keyword"
}

# Get-Response
function Get-Response([string]$url, [int]$delay = 100, [int]$retry = 10) {
    for ($try = 0; $try -lt $retry; $try++) {
        # delay
        Start-Sleep -Milliseconds $delay
        # web request
        try {$res = Invoke-WebRequest $url} catch {} # web request
        if ($res.StatusCode -eq 200) {
            return $res.Content # success
        }
    }
    return "Get-Response.Error.Web" # error
}

# Get-Album
function Get-Album([string]$code) {
    # web request
    $res = Get-Response (Get-DLsite $code)
    # match title
    if ($res -match "<h1 itemprop=`"name`" id=`"work_name`">\s*(.+)\s*</h1>") {
        return @{code = $code; title = $matches[1]; arch = $true; excl = $false}
    } else {
        return @{code = $code; title = "Get-Album.Error.Title"; arch = $true; excl = $false}
    }
}

# Get-Series
function Get-Series([string]$code) {
    # web request
    $res = Get-Response (Get-DLsite $code)
    # match series
    if ($res -match "<th>\s*シリーズ名\s*</th>\s*<td>\s*<a href=`".*/title_id/(\w+)/.*`">\s*(.+)\s*</a>\s*</td>") {
        return @{code = $matches[1]; title = $matches[2]; excl = $false; albums = @()} # series
    } else {
        return @{code = "SINGLE"; title = "Single"; excl = $false; albums = @()} # single
    }
}

# Get-Albums
function Get-Albums([string]$code) {
    # initialize
    $albums = @()
    $page = 0
    while ($true) {
        # next page
        $page++
        # web request
        $res = Get-Response (Get-DLsite $code $page)
        # match albums
        $matches = ($res | Select-String "<div class=`"multiline_truncate`">\s*<a href=`".*/product_id/(\w+).html`" title=`".*`">\s*(.+)\s*</a>\s*</div>" -AllMatches).Matches
        # append album
        foreach ($match in $matches) {
            $albums += @{code = $match.Groups[1].Value; title = $match.Groups[2].Value; arch = $false; excl = $false}
        }
        # check next page
        if ($res -notmatch "<li>\s*<a href=`".*`" data-value=`".*`">\s*次へ\s*</a>\s*</li>") {
            break # last page, return
        }
    }
    return $albums
}

