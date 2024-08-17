function checksize() {
    # du -h -d 1 <dir> | sort -hr
    directory=$1
    if [[ -z "$directory" ]]; then
        directory="$HOME"
    fi
    du -h -d 1 "$directory" | sort -hr
}