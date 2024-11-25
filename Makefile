FLATPAK_ID=org.jellyfin.JellyfinServer
MANIFEST=$(FLATPAK_ID).yml
APPMETA=$(FLATPAK_ID).metainfo.xml
TAG_JELLYFIN := $(shell curl -s https://api.github.com/repos/jellyfin/jellyfin/tags | jq -r .[0].name)
TAG_JELLYFIN_WEB := $(shell curl -s https://api.github.com/repos/jellyfin/jellyfin-web/tags | jq -r .[0].name)
VERSION := $(TAG_JELLYFIN)
# TODO: Needs to be reworked.
#VERSION := $(shell cat VERSION)
DOT_NET_VER=8
LLVM_VER=19
NODE_VER=22
RUNTIME_VER=24.08
BUILD_DATE := $(shell date -I)
GH_ACCOUNT := $(shell gh auth status --active | grep "Logged in to github.com account" | cut -d " " -f 9)

.PHONY: all clean remove-sources reset setup-sdk prepare pkg pkg-x64 pkg-arm64 run bundle bundle-x64 bundle-arm64 lint check-meta check-versions release generate-sources refresh-sources workflow-check workflow-gau-schedule-disable workflow-gau-schedule-enable

all: setup-sdk prepare refresh-sources pkg-x64 bundle

clean:
	rm -rf build-dir_x86_64 build-dir_aarch64 .flatpak-builder repo

refresh-sources: remove-sources generate-sources

remove-sources:
	rm -fv npm-generated-sources.json nuget-generated-sources-x64.json nuget-generated-sources-arm64.json

generate-sources: npm-generated-sources.json nuget-generated-sources-x64.json nuget-generated-sources-arm64.json

# Removes everything.
reset: clean remove-sources
	rm -rf jellyfin/ jellyfin-web/
	rm -rf flatpak-builder-tools/
	rm -f checksums.txt

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

prepare:
	$(info Jellyfin: $(TAG_JELLYFIN), Jellyfin Web: $(TAG_JELLYFIN_WEB))
#	In case this repository was cloned without initializing sub modules.
	git submodule update --init --recursive
#	ifeq ($(TAG_JELLYFIN),$(TAG_JELLYFIN_WEB))
#	$(info This is version $(TAG_JELLYFIN))
	git -c advice.detachedHead=false clone --depth 1 -b "$(TAG_JELLYFIN)" https://github.com/jellyfin/jellyfin.git
	git -c advice.detachedHead=false clone --depth 1 -b "$(TAG_JELLYFIN_WEB)" https://github.com/jellyfin/jellyfin-web.git

#	echo "$(TAG_JELLYFIN)" > VERSION

	git -c advice.detachedHead=false clone --depth 1 https://github.com/flatpak/flatpak-builder-tools.git
	pipx install "./flatpak-builder-tools/node/"
#	else
#	  $(info Warning version numbers don't match $(TAG_JELLYFIN) vs. $(TAG_JELLYFIN_WEB))
#	endif

pkg: pkg-x64 pkg-arm64

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
pkg-arm64: $(MANIFEST)
	flatpak --user run org.flatpak.Builder \
	  --user \
	  --arch aarch64 \
	  --repo "repo" \
	  --force-clean \
	  "build-dir_aarch64" \
	  "$(MANIFEST)"

run:
	flatpak run $(FLATPAK_ID)

bundle: bundle-x64 bundle-amd64

bundle-x64:
	flatpak build-bundle \
	  "repo" \
	  --arch x86_64 \
	  "JellyfinServer-$(VERSION)-TESTING-$(BUILD_DATE)-amd64.flatpak" \
	  "org.jellyfin.JellyfinServer"

bundle-arm64:
	flatpak build-bundle \
	  "repo" \
	  --arch aarch64 \
	  "JellyfinServer-$(VERSION)-TESTING-$(BUILD_DATE)-arm64.flatpak" \
	  "org.jellyfin.JellyfinServer"
	sha512sum JellyfinServer-$(VERSION)-TESTING-$(BUILD_DATE)-*.flatpak > checksums.txt

# Only use this when you have bundles built for both platforms.
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

check-versions:
	sed -i -e 's/#\(branch:\)/\1/g' "$(MANIFEST)"
	flatpak run org.flathub.flatpak-external-data-checker "$(MANIFEST)"

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

workflow-check:
# Causes problems with code style and in some cases even breaks workflows.
# TODO: Replace soon.
#	action-updater update --quiet .github/workflows/
# Already included in pre-commit.
#	zizmor .github/workflows/
	pre-commit autoupdate

# Before pushing to Flathub.
workflow-gau-schedule-disable:
	sed -i 's/ \(schedule:\)/ #\1/' .github/workflows/ga-updater.yml
	sed -i 's/ \(- cron:\)/ #\1/' .github/workflows/ga-updater.yml
# After syncing with Flathub.
workflow-gau-schedule-enable:
	sed -i 's/ #\(schedule:\)/ \1/' .github/workflows/ga-updater.yml
	sed -i 's/ #\(- cron:\)/ \1/' .github/workflows/ga-updater.yml
