gcpp() {
    # check if passed argument already has .cpp extension, if yes, remove it
    local filename=$1
    local launch_program="g++"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        launch_program="/opt/homebrew/bin/g++-14"
    fi
    if [[ $filename == *.cpp ]]; then
        filename=${filename%.cpp}
    fi
    $launch_program -std=c++11 -o $filename $filename.cpp && ./$filename && rm $filename
}