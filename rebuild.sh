#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
# Absolute path: sudo's secure_path does not include /run/current-system/sw/bin.
exec sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/.dotfiles#mac
