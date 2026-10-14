#!/bin/bash
# Bootstrap a fresh Omarchy install into my development environment:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/JonnieKarlsson/setup/main/bootstrap.sh)
#
# Installs the GitHub CLI if needed, signs in, fetches my configuration (or updates it
# if it's already there) and applies it. Safe to run again.
set -uo pipefail

REPO=JonnieKarlsson/dotfiles
DIR=$HOME/dotfiles

bold() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die() { printf '\033[31m    %s\033[0m\n' "$*" >&2; exit 1; }

main() {
  bold "Checking this machine"
  [[ $EUID -ne 0 ]] || die "Run this as your normal user, not root (it uses sudo when it needs to)."
  [[ -d /usr/share/omarchy ]] || command -v omarchy >/dev/null || die "This doesn't look like Omarchy. Install Omarchy first."
  command -v git >/dev/null || die "git is missing."
  info "Omarchy $(omarchy version 2>/dev/null || echo '(version unknown)'), user $USER"

  bold "GitHub CLI"
  local -a gh
  if command -v gh >/dev/null; then
    gh=(gh)
  elif command -v mise >/dev/null; then
    info "installing gh with mise"
    mise install gh@latest || die "Couldn't install gh with mise. Check the network connection."
    gh=(mise exec gh@latest -- gh)
  else
    info "installing github-cli with pacman"
    omarchy pkg add github-cli || die "Couldn't install github-cli."
    gh=(gh)
  fi
  info "$("${gh[@]}" --version | head -1)"

  bold "GitHub login"
  if "${gh[@]}" auth status --hostname github.com >/dev/null 2>&1; then
    info "already logged in"
  else
    info "Sign in to continue. Pick 'Login with a web browser'."
    "${gh[@]}" auth login --hostname github.com --git-protocol https --web ||
      die "GitHub login failed. Run this script again to retry."
  fi

  # Let git use gh's token for this clone/pull only (the restored git config sets up gh for later).
  local git=(git -c credential.https://github.com.helper= -c "credential.https://github.com.helper=!${gh[*]} auth git-credential")

  bold "Configuration"
  if [[ -d $DIR/.git ]]; then
    info "updating $DIR"
    if [[ -n $(git -C "$DIR" status --porcelain) ]]; then
      info "it has uncommitted changes, so leaving it as it is (run 'dotfiles save' or commit them)"
    else
      "${git[@]}" -C "$DIR" pull --ff-only -q || die "Couldn't update $DIR. Fix it by hand, then run this again."
    fi
  elif [[ -e $DIR ]]; then
    die "$DIR exists but isn't a git repo. Move it away and run this again."
  else
    info "cloning $REPO to $DIR"
    "${git[@]}" clone -q "https://github.com/$REPO.git" "$DIR" || die "Couldn't clone $REPO."
  fi

  bold "Applying configuration (package installs ask for your sudo password)"
  "$DIR/dotfiles" restore "$@" || die "'dotfiles restore' failed. Fix the error above and run this again."

  bold "All set. Log out and back in (or reboot) so everything picks up the new config."
}

# Run interactive steps (gh login, sudo, prompts) from the terminal, even when this
# script is piped in with `curl ... | bash`. The whole `if` is read before it runs.
if [[ -t 0 ]]; then
  main "$@"
elif (: </dev/tty) 2>/dev/null; then
  main "$@" </dev/tty
else
  main "$@"
fi
