[no-cd]
count-modules: \
	count-modules-top-level \
	count-modules-external \
	count-modules-all

[no-cd]
count-modules-top-level:
	@echo "Top-Level Modules:"
	@yq '.modules | length' \
	"${MANIFEST}"

[no-cd]
count-modules-external:
	@echo "External Sources (Git Repositories + Archives):"
	@yq '[.. | .sources? | .[] | select(.type == "git" or .type == "archive")] | length' \
	"${MANIFEST}"

[no-cd]
count-modules-all:
	@echo "All Modules (Total Build Steps):"
	@yq '[.. | select(has("name"))] | length' \
	"${MANIFEST}"

[no-cd]
lint: \
	lint-manifest \
	lint-repo

[private]
[no-cd]
lint-manifest:
	flatpak run --command=flatpak-builder-lint org.flatpak.Builder \
	manifest "${MANIFEST}"

[private]
[no-cd]
lint-repo:
  #!/bin/bash

  if [[ -d "${REPO}" ]]; then
    flatpak run --command=flatpak-builder-lint org.flatpak.Builder \
      repo "${REPO}"
  else
    echo "No directory named '${REPO}' found. Nothing do do."
  fi

[no-cd]
check-manifest-versions:
	flatpak run org.flathub.flatpak-external-data-checker "${MANIFEST}" --filter-type extra-data 2>&1 | grep -v "^INFO"
	flatpak run org.flathub.flatpak-external-data-checker "${MANIFEST}" --filter-type file 2>&1 | grep -v "^INFO"
	flatpak run org.flathub.flatpak-external-data-checker "${MANIFEST}" --filter-type archive 2>&1 | grep -v "^INFO"
	flatpak run org.flathub.flatpak-external-data-checker "${MANIFEST}" --filter-type git 2>&1 | grep -v "^INFO"
	grep --line-number --color=always -E "dotnet[0-9]{1,2}" "${MANIFEST}"
	grep --line-number --color=always -E "llvm[0-9]{2}" "${MANIFEST}"
	grep --line-number --color=always -E "node[0-9]{2}" "${MANIFEST}"

[no-cd]
check-meta:
	flatpak run --command=appstreamcli org.flatpak.Builder validate \
	"${APPMETA}"
