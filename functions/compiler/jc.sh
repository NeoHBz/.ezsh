jc() {
    local filename=$1
    if [[ $filename == *.java ]]; then
        filename=${filename%.java}
    fi
    javac $filename.java && java $filename && rm $filename.class
}