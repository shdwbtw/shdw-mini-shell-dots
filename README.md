# shdw mini shell dots

A [Quickshell](https://quickshell.org) desktop shell for the [mango](https://github.com/DreamMaoMao/mangowc) Wayland compositor, with colors generated from the wallpaper by [matugen](https://github.com/InioX/matugen).

## Features

- **Bar**: a power menu (shutdown, reboot, lock, logout) and animated mango workspaces on the left, a dynamic island in the middle, and volume, brightness and battery on the right.
- **Dynamic island**
  - Shows the clock, and can also cycle to the track that's playing.
  - Hover to expand it into three tabs:
    - **Larp:** opens a set of floating terminals.
    - **Home:** media controls with album art, plus the time, date and calendar.
    - **Notifications:** the notification history.
  - Notifications pop up inside it.
  - Volume and brightness changes show a level bar.
  - It also holds the app launcher (`Super+R`) and the wallpaper picker (`Super+M`).
- **Control center**: hover the right side of the bar to show the tray. Click a status icon to open the panel:
  - volume and brightness sliders
  - output and input device picker
  - per-app volume mixer
  - battery and power profiles, plus a caffeine toggle that turns off dimming, locking and screen-off
  - Wi-Fi and Bluetooth, with a right-click menu on each network / device (disconnect, forget, auto-connect, copy password, edit; pair, unpair, trust, block, copy address)
- **Lockscreen**: a blurred screenshot of the desktop behind a block clock, with password authentication through PAM.
- **Idle**: dims the screen, then locks (only while no audio is playing), then turns the screens off. After an idle lock, any input within 5 seconds unlocks without a password.
- **Wallpaper theming**: picking a wallpaper sets it with `awww` and runs matugen. The new colors apply to the shell, mango's borders, kitty, a Discord (Equicord) theme and a spotifast theme.

## Dependencies

### Required

| Package | Used for |
|---|---|
| [mangowc](https://github.com/DreamMaoMao/mangowc) (with `mmsg`) | compositor; workspaces, window placement, IPC |
| [quickshell](https://quickshell.org) (0.3+, git) | the shell itself |
| Qt 6 (`qt6-declarative`, `qt6-wayland`) | QtQuick, `QtQuick.Effects`, `Qt.labs.folderlistmodel` |
| [JetBrainsMono Nerd Font](https://www.nerdfonts.com) | font and icons |
| PipeWire + WirePlumber | audio (volume, devices, mixer) |
| UPower | battery |
| power-profiles-daemon | performance / balanced / power saver buttons |
| NetworkManager | Wi-Fi list and connections |
| BlueZ | Bluetooth list and connections |
| `brightnessctl` | backlight control |
| `grim` | screenshot behind the lockscreen |
| `nmcli` (part of NetworkManager), `wl-clipboard` | Wi-Fi menu: auto-connect, copy password, edit; copying a Bluetooth address |
| `jq` (and `pw-dump`, part of PipeWire) | checking for playing audio before an idle lock |
| [awww](https://github.com/LGFae/awww) | wallpaper daemon (`awww-daemon`) |
| [matugen](https://github.com/InioX/matugen) (4.x) | colors from the wallpaper |
| `kitty` | terminal; also used by larp |
| `python3` | larp script |
| `libnotify` (`notify-send`) | larp / power-profile messages |
| PAM (`pam_unix`) | lockscreen password check (standard on most distros) |

### Optional

| Package | Used for |
|---|---|
| `nm-connection-editor` | "Network settings" button |
| `blueman` | "Bluetooth settings" button |
| `pavucontrol` | advanced audio settings |
| `nm-applet` or other tray apps | system tray |
| [Equicord](https://github.com/Equicord/Equicord) | Discord theme from `matugen/templates/MiniShell.css` |
| spotifast | player shown in the island; theme from `matugen/templates/spotifast-theme.json` |
| `cava`, `unimatrix`, `momoisay`, `peaclock`, [`tap`](https://github.com/timdubbins/tap) | the default larp programs (editable in the island) |

## Install

```sh
git clone https://github.com/shdwbtw/shdw-mini-shell-dots.git
cd shdw-mini-shell-dots

# back up your existing configs first, then:
cp -r quickshell mango matugen ~/.config/
cp kitty/kitty.conf ~/.config/kitty/
```

Then:

1. Put your wallpapers in `~/Pictures/Wallpaper`. To use another folder, change `dir` in `quickshell/services/Wallpaper.qml`.
2. Log back into mango. `config.conf` starts `awww-daemon` and `qs`.
3. Press `Super+M` and pick a wallpaper. This creates the generated theme files:
   - `~/.config/kitty/matugen-theme.conf`
   - `~/.config/mango/theme.conf`
   - the Equicord and spotifast themes

   Until you pick one, kitty has no theme file and the shell uses gruvbox fallback colors.

## Keybinds

| Keys | Action |
|---|---|
| `Super+R` | app launcher |
| `Super+M` | wallpaper picker |
| `Super+T` | kitty |
| `Super+Q` | close window |
| `Super+1…9` | switch workspace |

The rest are in `mango/bindings.conf`.

## IPC

```sh
qs ipc call launcher toggle
qs ipc call wallpaper toggle
qs ipc call wallpaper set /path/to/image.png
qs ipc call session lock
qs ipc call session setIdle 10   # minutes until auto-lock, 0 = off
qs ipc call idle caffeine        # toggle caffeine
qs ipc call idle setDim 4        # minutes until dim, 0 = off
qs ipc call idle setLock 5       # same as session setIdle
qs ipc call idle setScreenOff 10 # minutes until screens off, 0 = off
```

## Configuration

| What | Where |
|---|---|
| colors / sizes / animation speed | `quickshell/services/Theme.qml` (`useWallpaperColors: false` for fixed gruvbox) |
| idle dim / lock / screen-off times, dim level, unlock grace period | `quickshell/services/Idle.qml` |
| low battery threshold | `lowThreshold` in `quickshell/services/Power.qml` |
| music / clock cycling in the island | `cycleMusic` in `quickshell/island/CompactView.qml` |
| larp programs and window sizes | ⚙ in the island's larp tab, or `quickshell/larp.json` |
| larp terminal cell size | `CELL` in `quickshell/scripts/larp.py` (depends on kitty's font) |
| matugen outputs | `matugen/config.toml` (hooks must not print to stdout) |
