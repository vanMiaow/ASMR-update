
# convert to lyrics timestamp
function ConvertTo-LyricsTimestamp([string]$time) {
    # try match mm:ss.xxx
    if ($time -match "^\d{2}:\d{2}\.\d{3}$") {
        # no need to convert
        return "[" + $time + "]"
    }
    # try match hh:mm:ss.xxx
    if ($time -match "^(\d{2}):(\d{2})(:\d{2}\.\d{3})$") {
        # convert to mm:ss.xxx
        return "[" + ([int]$matches[1] * 60 + [int]$matches[2]).ToString("D2") + $matches[3] + "]"
    }
    # invalid timestamp
    return "[]"
}

# get webvtt files
$files = Get-ChildItem "./*" -Include "*.txt", "*.vtt" | Sort-Object Name
# get audio files (for rename)
$audios = Get-ChildItem "./*" -Include "*.wav", "*.flac", "*.mp3" | Sort-Object Name
# convert webvtt to lyrics
for ($i = 0; $i -lt $files.Count; $i++) {
    # get webvtt
    $file  = $files[$i].Name
    $lines = Get-Content $file
    # init lyrics
    $newFile  = $audios[$i].BaseName + ".lrc"
    $newLines = @()
    # init timestamp
    $start = ""
    $stop  = ""
    foreach ($line in $lines) {
        if ($start -and $stop) {
            # timestamp set
            if ($line.Length -gt 0) {
                # [start]lyrics
                $newLines += $start + $line
            } else {
                # [stop]
                $newLines += $stop
                # unset timestamp
                $start = ""
                $stop  = ""
            }
        } else {
            # timestamp not set
            if ($line -match "^([\d:.]+) --> ([\d:.]+)$") {
                # set timestamp
                $start = ConvertTo-LyricsTimestamp $matches[1]
                $stop  = ConvertTo-LyricsTimestamp $matches[2]
            }
        }
    }
    # write to lyrics file
    $newLines | Out-File $newFile
    echo ""
    echo $file
    echo $newFile
}
echo ""

