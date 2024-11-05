touchidsudo() {
    sudo echo >> /etc/pam.d/sudo
    sudo echo "auth       sufficient     pam_tid.so" >> /etc/pam.d/sudo
}