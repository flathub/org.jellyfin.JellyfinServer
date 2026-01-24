# cspell:ignore precommit prek debian Aptfile

[doc("Update pre-commit and git submodules")]
repo-update: \
	repo-update-precommit-prek \
	repo-update-submodules

[private]
repo-update-precommit-prek:
	prek auto-update

[private]
repo-update-submodules:
	git submodule update --init --remote --recursive
	git submodule status
	git status

repo-install-packages-debian:
	sudo apt install $(cat ../Aptfile)

pre-commit-run-all-files:
  #!/bin/bash

  for i in $(grep -e "- id:" "../../.pre-commit-config.yaml" | sed 's/ *- id: //g'); do
    read -n1 -rp "Use ${i}? (y/N) "

    if [[ "${REPLY}" == "y" ]]; then

      echo -e "\n${i}"
      prek run ${i} --all-files

    else

      echo -e "\nSkipped ${i}."

    fi
  done
