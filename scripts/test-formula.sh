#!/bin/bash
# Install and test formula files on this Mac without touching the real tap or anything already installed.
# Usage: test-formula.sh path/to/name.rb [more.rb ...]
# Each formula is copied into a throwaway local tap, built from source, tested, and removed again.
# Exit 0: all passed. Exit 4: a formula of that name is already installed here (left alone). Other: a failure.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 HOMEBREW_NO_AUTOREMOVE=1

# A tap name of this run's own, so nothing that already exists is ever reused or removed.
TAP="abe238/bumptest$$"
[ "$#" -gt 0 ] || { echo "usage: $0 formula.rb [...]"; exit 2; }

# Nothing below may touch a formula this Mac already has. If the list cannot be read, stop.
installed="$(brew list --formula -1 </dev/null)" || { echo "FAIL: could not list installed formulae"; exit 1; }
names=()
for f in "$@"; do
  [ -f "$f" ] || { echo "FAIL: no such file: $f"; exit 2; }
  n="$(basename "$f" .rb)"
  case $'\n'"$installed"$'\n' in
    *$'\n'"$n"$'\n'*) echo "SKIP: $n is already installed on this Mac; not touching it"; exit 4 ;;
  esac
  names+=("$n")
done

cleanup() {
  for n in "${names[@]}"; do
    brew uninstall --force "$TAP/$n" </dev/null >/dev/null 2>&1
    brew untrust --formula "$TAP/$n" </dev/null >/dev/null 2>&1
  done
  brew untap "$TAP" </dev/null >/dev/null 2>&1
}
trap cleanup EXIT

if brew tap </dev/null | grep -qx "$TAP"; then echo "FAIL: tap $TAP already exists"; trap - EXIT; exit 1; fi
brew tap-new --no-git "$TAP" </dev/null >/dev/null || { echo "FAIL: could not create the local tap"; exit 1; }
dir="$(brew --repository "$TAP")/Formula"
mkdir -p "$dir"

for i in "${!names[@]}"; do
  n="${names[$i]}"
  cp "${@:$((i + 1)):1}" "$dir/$n.rb"
  brew trust --formula "$TAP/$n" </dev/null >/dev/null 2>&1
  echo "== $n: install"
  brew install --build-from-source "$TAP/$n" </dev/null || { echo "FAIL: $n install"; exit 1; }
  echo "== $n: test"
  brew test "$TAP/$n" </dev/null || { echo "FAIL: $n test"; exit 1; }
  echo "PASS: $n"
done

# Leave nothing behind, and say so only after checking.
cleanup
trap - EXIT
left="$(brew list --formula -1 </dev/null)" || { echo "FAIL: could not list installed formulae after cleanup"; exit 1; }
for n in "${names[@]}"; do
  case $'\n'"$left"$'\n' in *$'\n'"$n"$'\n'*) echo "FAIL: $n is still installed after cleanup"; exit 1 ;; esac
done
taps="$(brew tap </dev/null)" || { echo "FAIL: could not list taps after cleanup"; exit 1; }
case $'\n'"$taps"$'\n' in *$'\n'"$TAP"$'\n'*) echo "FAIL: tap $TAP is still present after cleanup"; exit 1 ;; esac
echo "ALL PASSED: ${names[*]}"
