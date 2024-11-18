# How To Update Jellyfin Server Flatpak/Flathub Builder

* Prerequisites:
    * Setup flatpak and flatub with `--user` scope
    * Install pipx
    * Install support packages for building arm64 on x86_64
      (Debian: `apt install -y binfmt-support qemu-user-static`)
    * Install and configure https://cli.github.com/ 
* Remove old build-artifacts: `make reset`
* Run `make` to (re)-create all needed files
* Run `make pkg` to test the build
* Run `make release` to publish a release on your fork (optional)
    * Uncomment respective sections in the `Makefile` if you don't want to use GH CLI at all
* Quality control (optional)
    * Run `make lint` to check for linting issues
    * Run `make check-meta` to check for meta info compliance issues
