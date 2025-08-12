function gcd() {
    if git show-ref --verify --quiet refs/heads/dev; then
        git checkout dev
    else
        echo "dev branch not found"
    fi
}