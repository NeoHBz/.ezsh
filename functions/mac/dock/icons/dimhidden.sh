dimhidden() {
    if [[ $(defaults read com.apple.Dock showhidden) == 1 ]]; then
        defaults write com.apple.Dock showhidden -bool FALSE && killall Dock
    else
        defaults write com.apple.Dock showhidden -bool TRUE && killall Dock
    fi
}