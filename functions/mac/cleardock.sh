cleardock() {
    defaults write com.apple.dock persistent-apps -array
    killall Dock
}