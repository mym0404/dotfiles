#!/bin/zsh
set -euo pipefail

defaults_bin=/usr/bin/defaults

"$defaults_bin" write NSGlobalDomain AppleInterfaceStyle -string Dark
"$defaults_bin" write NSGlobalDomain AppleShowAllExtensions -bool true
"$defaults_bin" write NSGlobalDomain ApplePressAndHoldEnabled -bool false
"$defaults_bin" write NSGlobalDomain InitialKeyRepeat -float 11
"$defaults_bin" write NSGlobalDomain KeyRepeat -float 1.1
"$defaults_bin" write NSGlobalDomain NSWindowResizeTime -float 0.001
"$defaults_bin" write NSGlobalDomain com.apple.mouse.scaling -float 2
"$defaults_bin" write NSGlobalDomain com.apple.trackpad.scaling -float 2
"$defaults_bin" write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true
"$defaults_bin" write NSGlobalDomain AppleEnableMouseSwipeNavigateWithScrolls -bool false
"$defaults_bin" write NSGlobalDomain com.apple.trackpad.forceClick -bool true

"$defaults_bin" write com.apple.dock orientation -string right
"$defaults_bin" write com.apple.dock tilesize -int 43
"$defaults_bin" write com.apple.dock show-recents -bool false
"$defaults_bin" write com.apple.dock show-process-indicators -bool true
"$defaults_bin" write com.apple.dock wvous-br-corner -int 14
"$defaults_bin" write com.apple.dock launchanim -bool false
"$defaults_bin" write com.apple.dock expose-animation-duration -float 0.1
"$defaults_bin" write com.apple.dock mineffect -string scale
"$defaults_bin" write com.apple.dock autohide-delay -float 0
"$defaults_bin" write com.apple.dock autohide-time-modifier -float 0

"$defaults_bin" write com.apple.finder AppleShowAllFiles -bool true
"$defaults_bin" write com.apple.finder FXPreferredViewStyle -string clmv

for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  "$defaults_bin" write "$domain" Clicking -bool true
  "$defaults_bin" write "$domain" DragLock -bool false
  "$defaults_bin" write "$domain" Dragging -bool false
  "$defaults_bin" write "$domain" TrackpadCornerSecondaryClick -int 0
  "$defaults_bin" write "$domain" TrackpadFiveFingerPinchGesture -int 2
  "$defaults_bin" write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
  "$defaults_bin" write "$domain" TrackpadFourFingerPinchGesture -int 2
  "$defaults_bin" write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
  "$defaults_bin" write "$domain" TrackpadHandResting -bool true
  "$defaults_bin" write "$domain" TrackpadHorizScroll -bool true
  "$defaults_bin" write "$domain" TrackpadMomentumScroll -bool true
  "$defaults_bin" write "$domain" TrackpadPinch -bool true
  "$defaults_bin" write "$domain" TrackpadRightClick -bool true
  "$defaults_bin" write "$domain" TrackpadRotate -bool true
  "$defaults_bin" write "$domain" TrackpadScroll -bool true
  "$defaults_bin" write "$domain" TrackpadThreeFingerDrag -bool true
  "$defaults_bin" write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 0
  "$defaults_bin" write "$domain" TrackpadThreeFingerTapGesture -int 0
  "$defaults_bin" write "$domain" TrackpadThreeFingerVertSwipeGesture -int 0
  "$defaults_bin" write "$domain" TrackpadTwoFingerDoubleTapGesture -int 1
  "$defaults_bin" write "$domain" TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
  "$defaults_bin" write "$domain" USBMouseStopsTrackpad -bool false
done

"$defaults_bin" write com.apple.AppleMultitouchTrackpad ActuateDetents -bool true
"$defaults_bin" write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
"$defaults_bin" write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool false
"$defaults_bin" write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1

for domain in com.apple.AppleMultitouchMouse com.apple.driver.AppleBluetoothMultitouch.mouse; do
  "$defaults_bin" write "$domain" MouseButtonDivision -int 55
  "$defaults_bin" write "$domain" MouseButtonMode -string TwoButton
  "$defaults_bin" write "$domain" MouseHorizontalScroll -bool true
  "$defaults_bin" write "$domain" MouseMomentumScroll -bool true
  "$defaults_bin" write "$domain" MouseOneFingerDoubleTapGesture -int 0
  "$defaults_bin" write "$domain" MouseTwoFingerDoubleTapGesture -int 3
  "$defaults_bin" write "$domain" MouseTwoFingerHorizSwipeGesture -int 1
  "$defaults_bin" write "$domain" MouseVerticalScroll -bool true
done

"$defaults_bin" write NSGlobalDomain NSUserKeyEquivalents -dict-add $'\033Tab\033Duplicate Tab' '@d'
"$defaults_bin" write NSGlobalDomain NSUserKeyEquivalents -dict-add "'Tab>Duplicate Tab'" '@d'

"$defaults_bin" write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 31 '{ enabled = 1; value = { parameters = (99, 8, 1572864); type = standard; }; }'
"$defaults_bin" write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{ enabled = 1; value = { parameters = (65535, 80, 8388608); type = standard; }; }'
for shortcut_id in 79 80 81 82; do
  "$defaults_bin" write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$shortcut_id" '{ enabled = 1; }'
done
"$defaults_bin" write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 98 '{ enabled = 1; value = { parameters = (47, 44, 1179648); type = standard; }; }'

for process in Dock Finder SystemUIServer; do
  /usr/bin/killall "$process" 2>/dev/null || true
done
