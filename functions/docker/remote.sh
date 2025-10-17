# export DOCKER_TLS_VERIFY=$DOCKER_TLS_VERIFY
# export DOCKER_CERT_PATH=$DOCKER_CERT_PATH
# export DOCKER_HOST=$DOCKER_HOST

removeremote() {
    unset $(env | grep ^DOCKER | cut -d= -f1 | tr '\n' ' ' | sed 's/ $//')
}