
# number of columns
$cols = 3

# css style
function Html-Style() {
    return @(
        "<style>"
        "    .markdown-body table {"
        "        border-collapse: separate;"
        "        border-spacing: 8px 12px;"
        "    }"
        "    .markdown-body table td:not(:has(*)) {"
        "        visibility: hidden;"
        "    }"
        "    .markdown-body table td:has(b) {"
        "        --color-table-data: var(--color-markdown-table-border);"
        "    }"
        "    .markdown-body table td {"
        "        --color-table-data: var(--secondary-background-color);"
        "        width: $((100 / $cols).ToString('G4'))%;"
        "        padding: 0;"
        "        border: none;"
        "        border-radius: 0 0 4px 4px;"
        "        background: var(--color-table-data);"
        "        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);"
        "        position: relative;"
        "    }"
        "    .markdown-body table td span {"
        "        margin: 0 8px 8px 8px;"
        "        word-break: normal;"
        "        display: -webkit-box;"
        "        -webkit-box-orient: vertical;"
        "        -webkit-line-clamp: 3;"
        "        overflow: hidden;"
        "    }"
        "    .markdown-body table td div:last-child {"
        "        position: absolute;"
        "        right: 8px;"
        "        bottom: 8px;"
        "        padding-left: 40px;"
        "        background: linear-gradient(to left, var(--color-table-data) 60%, rgba(255, 255, 255, 0));"
        "    }"
        "    .markdown-body table td a {"
        "        margin-left: 4px;"
        "    }"
        "    .markdown-body summary img,"
        "    .markdown-body table td a:first-child img {"
        "        width: 16px;"
        "        margin-bottom: -2px;"
        "    }"
        "    .markdown-body table td a:last-child img {"
        "        width: 18px;"
        "        margin-bottom: -3px;"
        "    }"
        "</style>"
    )
}

# tag
function Html-Tag([string]$tag, [string[]]$inner) {
    return @(
        "<$tag>"
        $inner | ForEach-Object { "    $_" }
        "</$tag>"
    )
}

# details, open?ed by default
function Html-Details([string[]]$inner, [bool]$open = $false) {
    if ($open) {
        $attr = " open"
    }
    return @(
        "<details$attr>"
        $inner | ForEach-Object { "    $_" }
        "</details>"
    )
}

# span with bold? string
function Html-Span([string]$inner, [bool]$bold = $false) {
    if ($bold) {
        $bs = "<b>"
        $be = "</b>"
    }
    return @(
        "<span>"
        "    $bs$inner$be"
        "</span>"
    )
}

# image lazy? loaded, single-line
function Html-Img([string]$src, [bool]$lazy = $false) {
    if ($lazy) {
        $load = " loading='lazy'"
    }
    return "<img$load src='$src'>"
}

# link with icon, search code in DLsite (type = dlsite) or ASMR (type = search, translate, add), single-line
function Html-Link([string]$type, [string]$code) {
    if ($type -eq "dlsite") {
        $href = Get-DLsite $code
        $src = "https://www.dlsite.com/images/web/common/favicon.ico"
    } elseif ($type -in "search", "translate", "add") {
        $href = Get-ASMR $code
        $src = switch ($type) {
            "search" { "https://raw.githubusercontent.com/google/material-design-icons/refs/heads/master/png/action/search/materialicons/48dp/2x/baseline_search_black_48dp.png" }
            "translate" { "https://raw.githubusercontent.com/google/material-design-icons/refs/heads/master/png/action/translate/materialicons/48dp/2x/baseline_translate_black_48dp.png" }
            "add" { "https://raw.githubusercontent.com/google/material-design-icons/refs/heads/master/png/content/add_circle_outline/materialicons/48dp/2x/baseline_add_circle_outline_black_48dp.png" }
        }
    } else {
        $href = "Error.Html-Link.Href"
        $src = "Error.Html-Link.Src"
    }
    return "<a href='$href' target='_blank'>$(Html-Img $src)</a>"
}

# album table data with cover, title, and links
function Html-Album([hashtable]$album, [string]$type) {
    # table data
    return Html-Tag "td" @(
        # cover
        Html-Tag "div" (Html-Img $album.cover $true)
        # title, bold when type is translate or add
        Html-Span $album.title ($type -ne "search")
        # links of DLsite and ASMR
        Html-Tag "div" @(
            Html-Link "dlsite" $album.code
            Html-Link $type $album.code
        )
    )
}

# arrange table data in rows
function Html-Table([string[][]]$tds) {
    # table rows
    $trs = @()
    # every $cols table data into a table row
    for ($i = 0; $i * $cols -lt $tds.Count; $i++) {
        $trs += Html-Tag "tr" @(
            0 .. ($cols - 1) | ForEach-Object {
                if ($i * $cols + $_ -lt $tds.Count) {
                    $tds[$i * $cols + $_]
                } else { # pad with empty table data
                    "<td></td>"
                }
            }
        )
    }
    return Html-Tag "table" $trs
}

# series details with link, circle?, title and table of albums, open?ed by default
function Html-Series([hashtable]$series, [bool]$open, [string[][]]$albums) {
    $circle = $series.circle.name
    if ($circle) {
        $circle = "[$circle] "
    }
    # details
    return Html-Details @(
        # summary
        Html-Tag "summary" @(
            # link of DLsite
            Html-Link "dlsite" $series.code
            # series title with circle name if avaliable
            Html-Span "$circle$($series.title)" $true
        )
        # table
        Html-Table $albums
    ) $open
}

