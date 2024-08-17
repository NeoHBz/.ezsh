gccc() {
  gcc -o $1 $1.c && ./$1 && rm $1
}