chromeswipe() {
    defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool $([ $(defaults read com.google.Chrome AppleEnableSwipeNavigateWithScrolls) -eq 0 ] && echo 1 || echo 0)
}
# defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool FALSE