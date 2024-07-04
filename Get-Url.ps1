function Get-Url([string]$mode, [string]$keyword, [string]$page) {
    if ($mode -eq "album") { # album
        if ($keyword.Substring(0, 2) -eq "BJ") { # BJ
            $type = "books"
        } elseif ($keyword.Substring(0, 2) -eq "RJ") { # RJ
            $type = "maniax"
        } else { # invalid album prefix
            return "error/album/prefix"
        }
        return "https://www.dlsite.com/$type/work/=/product_id/$keyword.html"
    } elseif ($mode -eq "series") { # series
        if ($keyword.Substring(0, 5) -eq "TITLE") { # BJ
            $type = "books"
        } elseif ($keyword.Substring(0, 3) -eq "SRI") { # RJ
            $type = "maniax"
        } else { # invalid series prefix
            return "error/series/prefix"
        }
        return "https://www.dlsite.com/$type/fsr/=/title_id/$keyword/order/release/per_page/100/page/$page"
    } elseif ($mode -eq "asmr") { # asmr
        return "https://asmr.one/works?keyword=$keyword"
    } else { # invalid mode
        return "error/mode"
    }
}
