function checkStdin() {
    while true; do
        read -rp "$(printf '%b%s%b' "$_YLW" "$1" "$_R")" userInput
        if [[ $userInput =~ $2 ]]; then
            break
        fi
    done
    echo "$userInput"
}

function withProgress() {
    local text="$1"; shift
    if [[ $_UI_BACKEND == yad ]]; then
        (while true; do printf '1\n'; sleep 0.1; done) \
            | yad --progress --pulsate --no-buttons --auto-close \
                  --title="ReShade" --text="$text" --width=520 >/dev/null 2>&1 &
        local _yadPid=$!
        "$@"
        local _ret=$?
        kill "$_yadPid" 2>/dev/null || true
        wait "$_yadPid" 2>/dev/null || true
        return $_ret
    fi
    if [[ $_UI_BACKEND != cli ]]; then
        ui_infobox "ReShade" "$text" 10 70
        sleep 0.1
        ui_refresh_screen
    fi
    "$@"
}

function copyToClipboard() {
    local _text="$1"
    if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-copy &>/dev/null; then
        printf '%s' "$_text" | wl-copy >/dev/null 2>&1
        return $?
    fi
    if [[ -n ${DISPLAY:-} ]] && command -v xclip &>/dev/null; then
        printf '%s' "$_text" | xclip -selection clipboard >/dev/null 2>&1
        return $?
    fi
    if [[ -n ${DISPLAY:-} ]] && command -v xsel &>/dev/null; then
        printf '%s' "$_text" | xsel --clipboard --input >/dev/null 2>&1
        return $?
    fi
    return 1
}

function createTempDir() {
    tmpDir=$(mktemp -d)
    cd "$tmpDir" || printErr "Failed to create temp directory."
}

function removeTempDir() {
    cd "$MAIN_PATH" || exit
    [[ -d $tmpDir ]] && rm -rf "$tmpDir"
}
