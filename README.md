# Jellyfin Server on Flathub

Generate sources cache with GitHub Actions

https://github.com/istori1/jellyfin-flatpak-cache-sources

## Build locally for 10.9

```bash
git clone --recurse-submodules https://github.com/flathub/org.jellyfin.JellyfinServer
cd org.jellyfin.JellyfinServer

git clone --depth 1 https://github.com/flatpak/flatpak-builder-tools.git
git clone --depth 1 -b v10.9.9 https://github.com/jellyfin/jellyfin.git

flatpak --user install org.freedesktop.Sdk/x86_64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.dotnet8/x86_64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.llvm18/x86_64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.node20/x86_64/23.08

./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py --dotnet 8 --freedesktop 23.08 --runtime=linux-x64 nuget-generated-sources-x64.json jellyfin/Jellyfin.Server/Jellyfin.Server.csproj
./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py --dotnet 8 --freedesktop 23.08 --runtime=linux-arm64 nuget-generated-sources-arm64.json jellyfin/Jellyfin.Server/Jellyfin.Server.csproj

git clone --depth 1 -b v10.8.10 https://github.com/jellyfin/jellyfin-web.git
git clone --depth 1 -b v10.9.9 https://github.com/jellyfin/jellyfin-web.git

# TODO pipx install poetry
poetry install -C ./flatpak-builder-tools/node/
./flatpak-builder-tools/node/.venv/bin/flatpak-node-generator -o npm-generated-sources.json npm jellyfin-web/package-lock.json

flatpak-builder \
  --force-clean build-dir org.jellyfin.JellyfinServer.yml

flatpak-builder \
  --user \
  --install \
  --force-clean build-dir org.jellyfin.JellyfinServer.yml
```


## Generate cache localy (10.8)

#### Clone flatpak tools

`git clone --depth 1 https://github.com/flatpak/flatpak-builder-tools.git`

#### Generate cache for NuGet

`git clone --depth 1 -b v10.8.10 https://github.com/jellyfin/jellyfin.git`

`./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py --runtime=linux-x64 nuget-generated-sources-x64.json jellyfin/Jellyfin.Server/Jellyfin.Server.csproj`

`./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py --runtime=linux-arm64 nuget-generated-sources-arm64.json jellyfin/Jellyfin.Server/Jellyfin.Server.csproj`

#### Generate cache for npm

`git clone --depth 1 -b v10.8.10 https://github.com/jellyfin/jellyfin-web.git`

`pip install ./flatpak-builder-tools/node`

`.local/bin/flatpak-node-generator -o npm-generated-sources.json npm jellyfin-web/package-lock.json`

#### Remove source clones
`rm -rf {jellyfin,jellyfin-web,flatpak-builder-tools}`


## Branding & Icon

* Icon source: https://github.com/jellyfin/jellyfin-ux/blob/master/branding/android/release/app_icon_foreground.svg
* Used template: https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines/quality-guidelines/
