gccc() {
    local filename=$1
    if [[ $filename == *.c ]]; then
        filename=${filename%.c}
    fi
    gcc -o $filename $filename.c && ./$filename && rm $filename
}