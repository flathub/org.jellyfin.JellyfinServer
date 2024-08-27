# FAQ -- Jellyfin Server on Flathub

## About this FAQ

This is the FAQ for Jellyfin Server on Flathub.
The focus is to get Jellyfin running with this packaging format and to answer basic questions.
This is not a comprehensive guide.
If you cannot find an answer here you should consult the [official Jellyfin documentation](https://jellyfin.org/docs/).

## Why Flatpak?

- Universal packging format for all traditional and image-based Linux distributions.
- Robust sandboxing and security features with minimal ovehead and resource usage.
- Easier to manage than Docker and Kubernetes deployments.

## Where should I file which types of issues?

- Issues which can be identified as issues related to flatpak packaging should be filed here.
  - Please **do use the issue tracker to request version updates**.
- Issues related to `jellyfin`, `jellyfin-web`, `jellyfin-ffmpeg` and other components should be filed at the respective issue tracker.

## How to launch the application?

There are several ways to launch the application:

- From the desktop shortcut which uses the default launcher.

  This will launch the server in the background and wait 10 seconds before opening the web interface in your web browser.

- Default launcher from the command line:

  `flatpak run org.jellyfin.JellyfinServer`

  This is the CLI equivalent to launching from the desktop shortcut.

- Launcher script from the command line:

  `flatpak run --command=org.jellyfin.JellyfinServer.sh org.jellyfin.JellyfinServer`

  This is also the CLI equivalent to launching from the desktop shortcut.

- Jellyfin itself from the command line:

  `flatpak run --command=org.jellyfin.JellyfinServer org.jellyfin.JellyfinServer`

  Using this launch option will bypass the behaviour of the current launcher script.

## Enable Raspberry Pi 4 GPU

```bash
flatpak override --user --device=all org.jellyfin.JellyfinServer
```
