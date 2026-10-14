# setup

One command that takes a fresh [Omarchy](https://omarchy.org) install to my complete development environment.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/JonnieKarlsson/setup/main/bootstrap.sh)
```

## What it does

1. Checks that it's running on Omarchy, as a regular user.
2. Installs the GitHub CLI if needed and signs in.
3. Fetches my configuration and applies it: system packages, development toolchains, editor setup and desktop settings.

When it finishes, the machine is ready to work on, with no manual post-install steps.

## How it's built

- **Idempotent.** Safe to run again. Completed steps are skipped or redone harmlessly, so an interrupted run just continues.
- **Least privilege.** Runs as a normal user and asks for `sudo` only to install packages.
- **No secrets in this repository.** It contains only the bootstrap logic and authenticates before fetching anything.
- **Always current.** Every run uses the latest version of my configuration, so the command stays the same as the setup evolves.

## Note

This is built for my own machines and needs my GitHub account, so it won't do anything useful elsewhere. You're welcome to read it as a reference.
