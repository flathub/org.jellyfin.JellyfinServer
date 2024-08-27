# Jellyfin Server on Flathub

Generate sources cache with GitHub Actions

https://github.com/istori1/jellyfin-flatpak-cache-sources

## Backup data

Make a backup of your configuration data before you install a new version of
Jellyfin. A simple copy command could already save you a lot of trouble:

```bash
cp -a \
  "${HOME}/.var/app/org.jellyfin.JellyfinServer/" \
  "${HOME}/.var/app/org.jellyfin.JellyfinServer_bak_$(date -I)"
```

Remember to check and remove backups that you don't need anymore.

## Build locally for 10.9

```bash
# Clone the repository.
git clone --recurse-submodules https://github.com/flathub/org.jellyfin.JellyfinServer
cd "org.jellyfin.JellyfinServer"

# Clone Jellyfin sources.
git clone --depth 1 -b v10.9.10 https://github.com/jellyfin/jellyfin.git
git clone --depth 1 -b v10.9.10 https://github.com/jellyfin/jellyfin-web.git

# Fetch builder tools.
git clone --depth 1 https://github.com/flatpak/flatpak-builder-tools.git

# Install and run generator for node with pipx, recommended in the README.
cd "flatpak-builder-tools/node/"
pipx install .
cd -
flatpak-node-generator -o "npm-generated-sources.json" npm "jellyfin-web/package-lock.json"

# Alternative: Install and run generator for node with poetry.
# pipx install poetry
# poetry install -C ./flatpak-builder-tools/node/
# ./flatpak-builder-tools/node/.venv/bin/flatpak-node-generator \
#   -o "npm-generated-sources.json" npm "jellyfin-web/package-lock.json"
```

### Build for x86_64

```bash
# Install dependencies for x86_64.
flatpak --user install org.freedesktop.Platform/x86_64/23.08
flatpak --user install org.freedesktop.Sdk/x86_64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.dotnet8/x86_64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.llvm18/x86_64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.node20/x86_64/23.08

# Generate sources for DotNet.
./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py \
  --dotnet 8 --freedesktop 23.08 --runtime=linux-x64 \
  "nuget-generated-sources-x64.json" "jellyfin/Jellyfin.Server/Jellyfin.Server.csproj"

# Start the build process.
flatpak-builder \
  --user \
  --arch x86_64 \
  --repo "repo" \
  --force-clean \
  "build-dir_x86_64" \
  "org.jellyfin.JellyfinServer.yml"

# Install/test artifacts locally.
# flatpak-builder \
#   --user \
#   --install \
#   --force-clean "build-dir_x86_64" "org.jellyfin.JellyfinServer.yml"

# Create a redistributable bundle.
flatpak build-bundle \
  "repo" \
  --arch x86_64 \
  "JellyfinServer-version-TESTING-$(date -I)-amd64.flatpak" \
  "org.jellyfin.JellyfinServer"
```

### Build for arm64

```bash
# Install support packages for building arm64 on x86_64.
# NOTE:
# * Build will be slow. Waiting about 1 hour alone on webpack.
# * Build may take +3 hours on a fast 16 core machine with fast SSD.
# * Package names for other distributions skipped for brevity.
apt install -y binfmt-support qemu-user-static
# Install dependencies for arm64.
flatpak --user install org.freedesktop.Platform/aarch64/23.08
flatpak --user install org.freedesktop.Sdk/aarch64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.dotnet8/aarch64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.llvm18/aarch64/23.08
flatpak --user install org.freedesktop.Sdk.Extension.node20/aarch64/23.08

# Generate sources for DotNet.
./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py \
  --dotnet 8 --freedesktop 23.08 --runtime=linux-arm64 \
  "nuget-generated-sources-arm64.json" "jellyfin/Jellyfin.Server/Jellyfin.Server.csproj"

# Start the build process.
flatpak-builder \
  --user \
  --arch aarch64 \
  --repo "repo" \
  --force-clean \
  "build-dir_aarch64" \
  "org.jellyfin.JellyfinServer.yml"

# Create a redistributable bundle.
flatpak build-bundle \
  "repo" \
  --arch aarch64 \
  "JellyfinServer-version-TESTING-$(date -I)-arm64.flatpak" \
  "org.jellyfin.JellyfinServer"
```

## Generate cache localy (10.8)

### Clone flatpak tools

`git clone --depth 1 https://github.com/flatpak/flatpak-builder-tools.git`

### Generate cache for NuGet

`git clone --depth 1 -b v10.8.10 https://github.com/jellyfin/jellyfin.git`

`./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py --runtime=linux-x64 nuget-generated-sources-x64.json jellyfin/Jellyfin.Server/Jellyfin.Server.csproj`

`./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py --runtime=linux-arm64 nuget-generated-sources-arm64.json jellyfin/Jellyfin.Server/Jellyfin.Server.csproj`

### Generate cache for npm

`git clone --depth 1 -b v10.8.10 https://github.com/jellyfin/jellyfin-web.git`

`pip install ./flatpak-builder-tools/node`

`.local/bin/flatpak-node-generator -o npm-generated-sources.json npm jellyfin-web/package-lock.json`

### Remove source clones

`rm -rf {jellyfin,jellyfin-web,flatpak-builder-tools}`
