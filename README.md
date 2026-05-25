# Unofficial Jellyfin Server Flatpak on Flathub

> [!TIP]
> Get help here:
> [FAQ](https://github.com/flathub/org.jellyfin.JellyfinServer/wiki/FAQ-%E2%80%94-Frequently-Asked-Questions)
> |
> [Wiki](https://github.com/flathub/org.jellyfin.JellyfinServer/wiki)
> |
> [Offical Documentation](https://jellyfin.org/docs/)
> |
> [Flatpak Development](https://github.com/flathub/org.jellyfin.JellyfinServer/wiki/Development:-How-build-the-Flatpak-on-your-workstation%3F)

## Maintainers

* [lwbt](https://github.com/lwbt) (active)
* [istori1](https://github.com/istori1) (inactive) - Initial creator of the Flatpak version
* [joshuaboniface](https://github.com/joshuaboniface) (shadow) - Jellyfin Project leader; not active maintainer but providing checks and balances for verification

New co-maintainers are welcome, check the development section in the Wiki if you are interested.

## How is this repository maintained?

* GitHub Depandabot regularly checks for updated modules in the manifest, submits PRs and starts builds.
* The repository contains GitHub Action Workflows and scripts (`make` / `just`) for recurring maintenance.
  The GitHub Action Workflows are preferred.

### How to publish new releases to Flathub?

New Jellyfin releases are also module updates in the manifest.

> [!IMPORTANT]
> When a new Jellyfin version is released and a PR is automatically submitted, the `regenerate-sources.yml` Action Workflow needs to be run on the respective branch of the PR, which will create a new PR that should be merged with the PR that was created for the version upgrade.
> TODO: mermaid diagram.
> Alternatively a repository maintainer runs `make refresh-sources` and adds a commit the the PR branch.

## Installation

<table cellspacing="0" cellpadding="0" >
  <tr>
    <td>
      <a href='https://flathub.org/apps/org.jellyfin.JellyfinServer'>
        <img lt='Jellyfin Icon' src='./branding/org.jellyfin.JellyfinServer.svg'/>
      </a>
    </td>
    <td>
      <a href='https://flathub.org/apps/org.jellyfin.JellyfinServer'>
        <img width='240' alt='Get it on Flathub' src='https://flathub.org/api/badge?locale=en'/>
      </a>
    </td>
  </tr>
</table>
