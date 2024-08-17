gcpp() {
    # check if passed argument already has .cpp extension, if yes, remove it
    local filename=$1
    if [[ $filename == *.cpp ]]; then
        filename=${filename%.cpp}
    fi
    g++ -o $filename $filename.cpp && ./$filename && rm $filename
}