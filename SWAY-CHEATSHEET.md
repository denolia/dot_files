# Sway Cheat Sheet

This cheat sheet matches the current config in this repo.

## Minimal Survival

- `Super+T`: open terminal
- `Super+Q`: close focused window
- `Super+R`: open app launcher (`rofi -show drun`)
- `Super+E`: open file manager
- `Super+V`: toggle focused window between tiled and floating
- `Super` + left-drag: move a floating window
- `Super` + right-drag: resize a floating window
- `Super+Left` / `Super+Right` / `Super+Up` / `Super+Down`: change focus
- `Super+1` ... `Super+0`: switch to workspace 1 ... 10
- `Super+Shift+1` ... `Super+Shift+0`: move focused window to workspace 1 ... 10
- `Super+Shift+S`: send focused window to scratchpad
- `Super+S`: show or hide scratchpad window

## All Shortcuts

### Apps and Session

- `Super+T`: open terminal
- `Super+Q`: close focused window
- `Super+R`: open app launcher (`rofi -show drun`)
- `Super+E`: open file manager
- `Super+M`: exit Sway session

### Layout and Windows

- `Super+V`: toggle focused window between tiled and floating
- `Super+J`: split focused window opposite to its parent for the next tiled window
- `Super+Shift+J`: toggle the focused container between horizontal and vertical split
- `Super+P`: no-op placeholder for Hyprland pseudotile

### Focus Movement

- `Super+Left`: focus left
- `Super+Right`: focus right
- `Super+Up`: focus up
- `Super+Down`: focus down

### Workspaces

- `Super+1` ... `Super+0`: switch to workspace 1 ... 10
- `Super+Shift+1` ... `Super+Shift+0`: move focused window to workspace 1 ... 10

### Scratchpad

- `Super+Shift+S`: move focused window to scratchpad
- `Super+S`: show or hide scratchpad

### Mouse

- `Super` + left-drag on a floating window: move window
- `Super` + right-drag on a floating window: resize window
- `Super` + mouse wheel up: previous workspace on current output
- `Super` + mouse wheel down: next workspace on current output

### Audio

- `XF86AudioRaiseVolume`: raise volume by 5%
- `XF86AudioLowerVolume`: lower volume by 5%
- `XF86AudioMute`: toggle speaker mute
- `XF86AudioMicMute`: toggle microphone mute

### Brightness

- `XF86MonBrightnessUp`: raise brightness by 5%
- `XF86MonBrightnessDown`: lower brightness by 5%

### Media Playback

- `XF86AudioNext`: next track
- `XF86AudioPause`: play or pause
- `XF86AudioPlay`: play or pause
- `XF86AudioPrev`: previous track

### Screenshots

- `F12`: full-screen screenshot to `~/Pictures`
- `Shift+F12`: area screenshot to `~/Pictures`
- `Ctrl+Shift+F12`: copy selected area screenshot to clipboard

## Notes

- Mouse move and resize work only for floating windows.
- If a window is tiled, press `Super+V` first to make it floating.
- Scratchpad windows usually reappear centered when shown again.
