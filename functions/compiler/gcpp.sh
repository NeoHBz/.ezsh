gcpp() {
    # check if passed argument already has .cpp extension, if yes, remove it
    local filename=$1
    if [[ $filename == *.cpp ]]; then
        filename=${filename%.cpp}
    fi
    g++ -std=c++11 -o $filename $filename.cpp && ./$filename && rm $filename
}