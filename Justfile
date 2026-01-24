mod repo "SCRIPTS/just/repo.just"
mod flatpak-manifest "SCRIPTS/just/flatpak-manifest.just"

export FLATPAK_ID := "org.jellyfin.JellyfinServer"
export MANIFEST := FLATPAK_ID + ".yml"
export APPMETA := FLATPAK_ID + ".metainfo.xml"
export REPO := "repo"

default:
	just --list --list-submodules
