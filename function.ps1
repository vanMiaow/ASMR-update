
# Get-DLsite
function Get-DLsite([string]$code, [int]$page = 1) {
    $prefix = $code.Substring(0, 2)
    if ($prefix -eq "RJ") { # album
        return "https://www.dlsite.com/maniax/work/=/product_id/$code.html"
    } elseif ($prefix -eq "SR") { # series
        return "https://www.dlsite.com/maniax/fsr/=/title_id/$code/order/release/per_page/100/page/$page"
    } else { # error
        return "https://www.dlsite.com/maniax/works/type/=/work_type_category/audio"
    }
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
        try { $res = Invoke-WebRequest $url } catch {} # web request
        if ($res.StatusCode -eq 200) {
            return $res.Content # success
        }
    }
    return "Error.Get-Response.Web" # error
}

# Get-Album
function Get-Album([string]$code) {
    # web request
    $res = Get-Response (Get-DLsite $code)
    # match title
    if ($res -match '<h1 itemprop="name" id="work_name">(.+)</h1>') {
        $title = $matches[1]
    } else {
        $title = "Error.Get-Album.Title"
    }
    # match circle
    if ($res -match '<a href=".+/maker_id/(\w+).html">(.+)</a>') {
        $circle = @{ code = $matches[1]; name = $matches[2] }
    } else {
        $circle = @{ code = "Error.Get-Album.Circle.Code"; name = "Error.Get-Album.Circle.Name" }
    }
    # match series
    if ($res -match '<a href=".+/title_id/(\w+)/.+titles">(.+)</a>') {
        $series = @{ code = $matches[1]; title = $matches[2] }
    } else {
        $series = @{ code = "SINGLE"; title = "Single" }
    }
    # match artist
    if ($res -match '<th>声優</th>\s+<td>(?s:.+?)</td>') {
        $artist = (([regex]'>(.+)</a>').Matches($matches[0]) | ForEach-Object { $_.Groups[1].Value }) -join " / "
    } else {
        $artist = "Error.Get-Album.Artist"
    }
    # match cover
    if ($res -match '<div data-src="(.+img_main.jpg)".+></div>') {
        $cover = "https:" + $matches[1]
    } else {
        $cover = "Error.Get-Album.Cover"
    }
    # match translation
    if ($res -match '<div class="work_edition_linklist type_trans">(?s:.+?)</div>' -and $matches[0] -match '中文') {
        $trans = $true
    } else {
        $trans = $false
    }
    return @{ code = $code; title = $title; circle = $circle; series = $series; artist = $artist; cover = $cover; trans = $trans }
}

# Get-Series
function Get-Series([string]$code) {
    # init
    $albums = @()
    $page = 0
    while ($true) {
        # next page
        $page++
        # web request
        $res = Get-Response (Get-DLsite $code $page)
        if (-not $title) { # first
            # match title
            if ($res -match '<span itemprop="name">「(.+)」シリーズ</span>') {
                $title = $matches[1]
            } else {
                $title = "Error.Get-Series.Title"
            }
            # match circle
            if ($res -match '<a.+\s+href=".+/maker_id/(\w+).html">\s+<span itemprop="name">(.+)</span>') {
                $circle = @{ code = $matches[1]; name = $matches[2] }
            } else {
                $circle = @{ code = "Error.Get-Series.Circle.Code"; name = "Error.Get-Series.Circle.Name" }
            }
        }
        # match albums
        ([regex]'<img src=".+" :src="is_show.+(//img.+/(\w+)_img_main.jpg).+" alt="(.+) \[.+\]">').Matches($res) | ForEach-Object {
            $albums += @{ code = $_.Groups[2].Value; title = $_.Groups[3].Value; cover = "https:" + $_.Groups[1].Value }
        }
        # check next page
        if ($res -notmatch '<a href=".+" data-value=".+">次へ</a>') {
            break # last page, return
        }
    }
    return @{ code = $code; title = $title; circle = $circle; albums = $albums }
}

