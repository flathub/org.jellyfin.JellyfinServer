.PHONY: repo-update
repo-update: repo-update-submodules repo-update-precommit-prek

.PHONY: repo-update-precommit-prek
repo-update-precommit-prek:
	prek auto-update

.PHONY: repo-update-submodules
repo-update-submodules:
	git submodule update --init --remote --recursive
	git submodule status
	git status

# TODO: Check if any of this is still relevant to maintain repo health.
#.PHONY: workflow-check
#workflow-check:
## Causes problems with code style and in some cases even breaks workflows.
## TODO: Replace soon.
##       action-updater update --quiet .github/workflows/
#
## Before pushing to Flathub.
#.PHONY: workflow-gau-schedule-disable
#workflow-gau-schedule-disable:
#	sed -i 's/ \(schedule:\)/ #\1/' .github/workflows/ga-updater.yml
#	sed -i 's/ \(- cron:\)/ #\1/' .github/workflows/ga-updater.yml
## After syncing with Flathub.
#.PHONY: workflow-gau-schedule-enable
#workflow-gau-schedule-enable:
#	sed -i 's/ #\(schedule:\)/ \1/' .github/workflows/ga-updater.yml
#	sed -i 's/ #\(- cron:\)/ \1/' .github/workflows/ga-updater.yml
