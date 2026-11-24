#!/bin/bash
# Daily job for a Mac: find new published versions, test the updated formulae on a Mac, and only then ask
# GitHub to publish them. No GitHub runner does any installing; GitHub only writes the already-tested files.
#
# Settings (environment):
#   TAP_TEST_HOST  ssh host to install and test on. Empty: test on this Mac.
#   TAP_NOTIFY     a command that reads a message on standard input (for example a chat sender). Optional.
#   TAP_FORCE      formula names to test and send through even when nothing changed (to try the path).
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

REPO="abe238/homebrew-tap"
HOST="${TAP_TEST_HOST:-}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

say() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }
notify() {
  say "NOTIFY: $1"
  if [ -n "${TAP_NOTIFY:-}" ]; then printf 'homebrew-tap: %s\n' "$1" | "$TAP_NOTIFY" >/dev/null 2>&1 || say "notify command failed"; fi
}
fail() { notify "FAILED. $1"; exit 1; }

git clone -q --depth 1 "https://github.com/$REPO" "$work/tap" || fail "Could not clone the tap."
cd "$work/tap" || fail "Clone folder is missing."

python3 -I scripts/bump.py > "$work/bump.log" 2>&1
rc=$?
cat "$work/bump.log"
[ "$rc" -eq 0 ] || fail "The version check stopped with an error: $(tail -1 "$work/bump.log")"
grep -q '^CHANGED: ' "$work/bump.log" || fail "The version check printed no result line."
names="$(sed -n 's/^CHANGED: //p' "$work/bump.log")"
[ -n "${TAP_FORCE:-}" ] && names="$names $TAP_FORCE"
names="$(echo $names)"
if [ -z "$names" ]; then say "Nothing new."; exit 0; fi
say "To test: $names"

files=()
tested=""
for n in $names; do
  f="Formula/$n.rb"
  [ -f "$f" ] || fail "No formula file for $n."
  v="$(sed -En 's/^  url ".*[-v]([0-9][0-9.]*[0-9])\.(tgz|tar\.gz)"$/\1/p' "$f")"
  s="$(sed -En 's/^  sha256 "([0-9a-f]{64})"$/\1/p' "$f")"
  case "$v$s" in *[!0-9a-f.]*|"") fail "Could not read the version and checksum of $n." ;; esac
  [ "${#s}" -eq 64 ] || fail "Could not read one checksum for $n."
  files+=("$f")
  tested="$tested $n=$v=$s"
done
tested="$(echo $tested)"

if [ -n "$HOST" ]; then
  dir="$(ssh -o BatchMode=yes -o ConnectTimeout=20 "$HOST" 'mktemp -d' </dev/null)" || fail "Could not reach the test Mac ($HOST). Nothing was published; it will try again tomorrow."
  scp -q -o BatchMode=yes scripts/test-formula.sh "${files[@]}" "$HOST:$dir/" || fail "Could not copy files to the test Mac."
  args=""
  for f in "${files[@]}"; do args="$args $dir/$(basename "$f")"; done
  ssh -o BatchMode=yes "$HOST" "bash $dir/test-formula.sh $args; rc=\$?; rm -rf $dir; exit \$rc" </dev/null > "$work/test.log" 2>&1
  rc=$?
else
  bash scripts/test-formula.sh "${files[@]}" > "$work/test.log" 2>&1
  rc=$?
fi
grep -E '^(==|PASS|FAIL|SKIP|ALL PASSED)' "$work/test.log"
if [ "$rc" -ne 0 ] || ! grep -q '^ALL PASSED' "$work/test.log"; then
  fail "Install or test did not pass for: $names. Nothing was published. Last lines: $(tail -3 "$work/test.log" | tr '\n' ' ')"
fi

before="$(gh run list -R "$REPO" --workflow bump.yml -L 1 --json databaseId --jq '.[0].databaseId // 0')" || fail "Could not read GitHub runs (sign-in?). Tests passed but nothing was published."
gh workflow run bump.yml -R "$REPO" -f tested="$tested" || fail "Could not start the publish run. Tests passed but nothing was published."
id=""
for _ in $(seq 1 30); do
  id="$(gh run list -R "$REPO" --workflow bump.yml -L 1 --json databaseId --jq '.[0].databaseId // 0')"
  [ -n "$id" ] && [ "$id" != "$before" ] && break
  id=""
  sleep 4
done
[ -n "$id" ] || fail "The publish run did not appear. Tests passed but nothing was published."
gh run watch "$id" -R "$REPO" --exit-status > "$work/watch.log" 2>&1 || fail "The publish run failed: https://github.com/$REPO/actions/runs/$id"

# Read back what main now holds; a green run is not the proof.
for t in $tested; do
  n="${t%%=*}"; rest="${t#*=}"; v="${rest%%=*}"; s="${rest#*=}"
  live="$(gh api "repos/$REPO/contents/Formula/$n.rb?ref=main" --jq .content | base64 -d)" || fail "Could not read $n back from main."
  echo "$live" | grep -q "$s" || fail "main does not hold the tested $n $v after the publish run."
done
if [ -n "${TAP_FORCE:-}" ] && [ -z "$(sed -n 's/^CHANGED: //p' "$work/bump.log")" ]; then
  say "Trial run passed: $tested"
else
  notify "Published after passing tests: $(echo "$tested" | sed -E 's/=([^= ]+)=[0-9a-f]{64}/ \1/g')"
fi
