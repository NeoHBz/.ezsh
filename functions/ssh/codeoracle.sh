# alias oraclecode="code --folder-uri 'vscode-remote://ssh-remote+neo@oracle/home/neo/docker'"
codeoracle() {
    base_dir="/home/neo/docker"
    if [ -n "$1" ]; then
        base_dir="$1"
    fi
    code --folder-uri "vscode-remote://ssh-remote+neo@oracle${base_dir}"
}