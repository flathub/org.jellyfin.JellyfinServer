include MAKEFILES/Makefile-repo.mk

FLATPAK_ID=org.jellyfin.JellyfinServer
MANIFEST=$(FLATPAK_ID).yml
APPMETA=$(FLATPAK_ID).metainfo.xml
DOT_NET_VER := $(shell awk -F'dotnet' '/org\.freedesktop\.Sdk\.Extension\.dotnet[0-9]+/ {print $$2+0}' $(MANIFEST))
LLVM_VER := $(shell awk -F'llvm' '/org\.freedesktop\.Sdk\.Extension\.llvm[0-9]+/ {print $$2+0}' $(MANIFEST))
NODE_VER := $(shell awk -F'node' '/org\.freedesktop\.Sdk\.Extension\.node[0-9]+/ {print $$2+0}' $(MANIFEST))
RUNTIME_VER := $(shell yq .runtime-version $(MANIFEST))
BUILD_DATE := $(shell date -I)

.PHONY: all
all: setup-sdk prepare refresh-sources add-new-release-to-meta check-meta pkg-x64 lint bundle

.PHONY: maintenance
maintenance: prepare setup-sdk-light refresh-sources add-new-release-to-meta check-meta lint

.PHONY: clean
clean:
	rm -rf build-dir_x86_64 build-dir_aarch64 .flatpak-builder repo VERSION_TAG_JELLYFIN.txt VERSION_TAG_JELLYFIN_WEB.txt

.PHONY: refresh-sources
refresh-sources: remove-sources generate-sources

.PHONY: remove-sources
remove-sources:
	rm -fv npm-generated-sources.json nuget-generated-sources-x64.json nuget-generated-sources-arm64.json

.PHONY: generate-sources
generate-sources: npm-generated-sources.json nuget-generated-sources-x64.json nuget-generated-sources-arm64.json

# Removes everything.
.PHONY: reset
reset: clean remove-sources
	rm -rf jellyfin/ jellyfin-web/
	rm -rf flatpak-builder-tools/
	rm -f checksums.txt

.PHONY: setup-sdk
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
	flatpak --user install -y org.flathub.flatpak-external-data-checker

.PHONY: setup-sdk-light
setup-sdk-light:
	flatpak --user install -y flathub org.flatpak.Builder
	flatpak --user install -y org.freedesktop.Sdk/x86_64/$(RUNTIME_VER)
	flatpak --user install -y org.freedesktop.Sdk.Extension.dotnet$(DOT_NET_VER)/x86_64/$(RUNTIME_VER)
	flatpak --user install -y org.flathub.flatpak-external-data-checker

VERSION_TAG_JELLYFIN.txt:
	curl -s https://api.github.com/repos/jellyfin/jellyfin/tags \
	| jq -r .[0].name > VERSION_TAG_JELLYFIN.txt

VERSION_TAG_JELLYFIN_WEB.txt:
	curl -s https://api.github.com/repos/jellyfin/jellyfin-web/tags \
	| jq -r .[0].name > VERSION_TAG_JELLYFIN_WEB.txt

.PHONY: prepare
prepare: VERSION_TAG_JELLYFIN.txt VERSION_TAG_JELLYFIN_WEB.txt
	$(info Jellyfin: $(shell cat VERSION_TAG_JELLYFIN.txt), Jellyfin Web: $(shell cat VERSION_TAG_JELLYFIN_WEB.txt))
#	In case this repository was cloned without initializing sub modules.
	git submodule update --init --recursive
#	ifeq ($(TAG_JELLYFIN),$(TAG_JELLYFIN_WEB))
#	$(info This is version $(TAG_JELLYFIN))
	git -c advice.detachedHead=false clone --depth 1 -b "$(shell cat VERSION_TAG_JELLYFIN.txt)" \
	https://github.com/jellyfin/jellyfin.git
	git -c advice.detachedHead=false clone --depth 1 -b "$(shell cat VERSION_TAG_JELLYFIN_WEB.txt)" \
	https://github.com/jellyfin/jellyfin-web.git
#
	git -c advice.detachedHead=false clone --depth 1 https://github.com/flatpak/flatpak-builder-tools.git
	pipx install "./flatpak-builder-tools/node/"
#	else
#	  $(info Warning version numbers don't match $(TAG_JELLYFIN) vs. $(TAG_JELLYFIN_WEB))
#	endif

.PHONY: pkg
pkg: pkg-x64 pkg-arm64

.PHONY: pkg-x64
pkg-x64: $(MANIFEST)
	flatpak --user run org.flatpak.Builder \
	  --user \
	  --arch x86_64 \
	  --repo "repo" \
	  --force-clean \
	  "build-dir_x86_64" \
	  "$(MANIFEST)"

# This takes over 3 hours compared to 30 minutes, which is why it is not
# included in make all implying that most developers still work on x86_64
# workstations.
.PHONY: pkg-arm64
pkg-arm64: $(MANIFEST)
	flatpak --user run org.flatpak.Builder \
	  --user \
	  --arch aarch64 \
	  --repo "repo" \
	  --force-clean \
	  "build-dir_aarch64" \
	  "$(MANIFEST)"

.PHONY: run
run:
	flatpak run $(FLATPAK_ID)

.PHONY: bundle
bundle: bundle-x64 bundle-arm64

.PHONY: bundle-x64
bundle-x64:
	flatpak build-bundle \
	  "repo" \
	  --arch x86_64 \
	  "JellyfinServer-$(shell cat VERSION_TAG_JELLYFIN.txt)-TESTING-$(BUILD_DATE)-amd64.flatpak" \
	  "org.jellyfin.JellyfinServer"

.PHONY: bundle-arm64
bundle-arm64:
	flatpak build-bundle \
	  "repo" \
	  --arch aarch64 \
	  "JellyfinServer-$(shell cat VERSION_TAG_JELLYFIN.txt)-TESTING-$(BUILD_DATE)-arm64.flatpak" \
	  "org.jellyfin.JellyfinServer"
	sha512sum JellyfinServer-$(shell cat VERSION_TAG_JELLYFIN.txt)-TESTING-$(BUILD_DATE)-*.flatpak > checksums.txt

# Only use this when you have bundles built for both platforms.
.PHONY: release
release:
	export GH_ACCOUNT=$(gh auth status --active | grep "Logged in to github.com account" | cut -d " " -f 9) \
	&& gh release create $(shell cat VERSION_TAG_JELLYFIN.txt) \
	  --repo $(GH_ACCOUNT)/org.jellyfin.JellyfinServer \
	  --title "$(shell cat VERSION_TAG_JELLYFIN.txt) $(BUILD_DATE)" \
	  --notes "Update Jellyfin to $(shell cat VERSION_TAG_JELLYFIN.txt). These are not CI/CD releases! The assets have been built on my workstation." \
	  --prerelease=false \
	  JellyfinServer-$(shell cat VERSION_TAG_JELLYFIN.txt)-TESTING-$(BUILD_DATE)-*.flatpak checksums.txt
#	  --draft \

.PHONY: add-new-release-to-meta
add-new-release-to-meta:
	MAKEFILES/add-new-release-to-meta.sh
	git diff "$(APPMETA)"

npm-generated-sources.json:
	flatpak-node-generator -o "npm-generated-sources.json" npm "jellyfin-web/package-lock.json"
	npx prettier --write "npm-generated-sources.json"

nuget-generated-sources-x64.json:
	./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py \
	  --dotnet $(DOT_NET_VER) --freedesktop $(RUNTIME_VER) --runtime=linux-x64 \
	  "nuget-generated-sources-x64.json" "jellyfin/Jellyfin.Server/Jellyfin.Server.csproj"
	npx prettier --write "nuget-generated-sources-x64.json"

nuget-generated-sources-arm64.json:
	./flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py \
	  --dotnet $(DOT_NET_VER) --freedesktop $(RUNTIME_VER) --runtime=linux-arm64 \
	  "nuget-generated-sources-arm64.json" "jellyfin/Jellyfin.Server/Jellyfin.Server.csproj"
	npx prettier --write "nuget-generated-sources-arm64.json"
