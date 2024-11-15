MANIFEST=org.jellyfin.JellyfinServer.yml
APPMETA=org.jellyfin.JellyfinServer.metainfo.xml
TAG_JELLYFIN := $(shell curl -s https://api.github.com/repos/jellyfin/jellyfin/tags | jq -r .[0].name)
TAG_JELLYFIN_WEB := $(shell curl -s https://api.github.com/repos/jellyfin/jellyfin-web/tags | jq -r .[0].name)
VERSION := $(shell cat VERSION)
DOT_NET_VER=8
LLVM_VER=19
NODE_VER=22
RUNTIME_VER=24.08
BUILD_DATE := $(shell date -I)
GH_ACCOUNT := $(gh auth status --active | grep "Logged in to github.com account" | cut -d " " -f 9)

.PHONY: all clean reset prepare pkg run bundle lint setup-sdk check-meta release

all: setup-sdk prepare npm-generated-sources.json nuget-generated-sources-x64.json nuget-generated-sources-arm64.json pkg bundle

clean:
	rm -rf build-dir_x86_64 build-dir_aarch64 .flatpak-builder repo 

reset: clean
	rm -rf jellyfin/ jellyfin-web/
	rm -rf flatpak-builder-tools/
	rm -f npm-generated-sources.json nuget-generated-sources-x64.json nuget-generated-sources-arm64.json checksums.txt

setup-sdk:
	flatpak --user install -y flathub org.flatpak.Builder
	flatpak --user install -y org.freedesktop.Platform/x86_64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk/x86_64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk.Extension.dotnet$(DOT_NET_VER)/x86_64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk.Extension.llvm$(LLVM_VER)/x86_64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk.Extension.node$(NODE_VER)/x86_64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Platform/aarch64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk/aarch64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk.Extension.dotnet$(DOT_NET_VER)/aarch64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk.Extension.llvm$(LLVM_VER)/aarch64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk.Extension.node$(NODE_VER)/aarch64/$(RUNTIME_VER)
	git -c advice.detachedHead=false clone --depth 1 https://github.com/flatpak/flatpak-builder-tools.git
	cd "flatpak-builder-tools/node/"
	pipx install .
	cd -

prepare:
	$(info Jellyfin: $(TAG_JELLYFIN), Jellyfin Web: $(TAG_JELLYFIN_WEB))
#	ifeq ($(TAG_JELLYFIN),$(TAG_JELLYFIN_WEB))
#	$(info This is version $(TAG_JELLYFIN))
	git -c advice.detachedHead=false clone --depth 1 -b "$(TAG_JELLYFIN)" https://github.com/jellyfin/jellyfin.git
	git -c advice.detachedHead=false clone --depth 1 -b "$(TAG_JELLYFIN_WEB)" https://github.com/jellyfin/jellyfin-web.git

	echo "$(TAG_JELLYFIN)" > VERSION
#	else
#	  $(info Warning version numbers don't match $(TAG_JELLYFIN) vs. $(TAG_JELLYFIN_WEB))
#	endif

pkg: $(MANIFEST)
	flatpak --user run org.flatpak.Builder \
	  --user \
	  --arch x86_64 \
	  --repo "repo" \
	  --force-clean \
	  "build-dir_x86_64" \
	  "$(MANIFEST)"
	flatpak --user run org.flatpak.Builder \
	  --user \
	  --arch aarch64 \
	  --repo "repo" \
	  --force-clean \
	  "build-dir_aarch64" \
	  "$(MANIFEST)"

bundle:
	flatpak build-bundle \
	  "repo" \
	  --arch x86_64 \
	  "JellyfinServer-$(VERSION)-TESTING-$(BUILD_DATE)-amd64.flatpak" \
	  "org.jellyfin.JellyfinServer"
	flatpak build-bundle \
	  "repo" \
	  --arch aarch64 \
	  "JellyfinServer-$(VERSION)-TESTING-$(BUILD_DATE)-arm64.flatpak" \
	  "org.jellyfin.JellyfinServer"
	sha512sum JellyfinServer-$(VERSION)-TESTING-$(BUILD_DATE)-*.flatpak > checksums.txt

release:
	gh release create $(VERSION) \
	  --repo $(GH_ACCOUNT)/org.jellyfin.JellyfinServer \
	  --title "$(VERSION) $(BUILD_DATE)" \
	  --notes "Update Jellyfin to $(VERSION). These are not CI/CD releases! The assets have been built on my workstation." \
	  --prerelease=false \
	  JellyfinServer-$(VERSION)-TESTING-$(BUILD_DATE)-*.flatpak checksums.txt
#	  --draft \

lint:
	flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest $(MANIFEST)
	flatpak run --command=flatpak-builder-lint org.flatpak.Builder repo repo

check-meta:
	flatpak run --command=appstream-util org.flatpak.Builder validate $(APPMETA)

npm-generated-sources.json:
	flatpak-node-generator -o "npm-generated-sources.json" npm "jellyfin-web/package-lock.json"

nuget-generated-sources-x64.json:
	./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py \
	  --dotnet $(DOT_NET_VER) --freedesktop $(RUNTIME_VER) --runtime=linux-x64 \
	  "nuget-generated-sources-x64.json" "jellyfin/Jellyfin.Server/Jellyfin.Server.csproj"

nuget-generated-sources-arm64.json:
	./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py \
	  --dotnet $(DOT_NET_VER) --freedesktop $(RUNTIME_VER) --runtime=linux-arm64 \
	  "nuget-generated-sources-arm64.json" "jellyfin/Jellyfin.Server/Jellyfin.Server.csproj"
