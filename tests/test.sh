#!/bin/sh
# Tests for install.sh. Uses a fake Firefox dir (path with a space); never your profiles.
# shellcheck disable=SC2015  # "a && b || fail": fail if either step fails
cd "$(dirname "$0")/.." || exit 1
REPO="$(pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
FIREFOX_DIR="$T/Firefox Data"; export FIREFOX_DIR
A="$FIREFOX_DIR/Profiles/aaa.default-release"; B="$FIREFOX_DIR/Profiles/bbb.default"
mkdir -p "$A" "$B" "$T/notaprofile"; touch "$A/prefs.js" "$B/prefs.js"
fails=0
fail() { echo "FAIL: $*"; fails=$((fails + 1)); }
ini() { printf '%s\n' '[Profile0]' 'Name=default-release' 'IsRelative=1' 'Path=Profiles/aaa.default-release' '' \
  '[Profile1]' 'Name=default' 'IsRelative=1' 'Path=Profiles/bbb.default' 'Default=1' '' "$@" > "$FIREFOX_DIR/profiles.ini"; }
ours() { [ "$1/user.js" -ef user.js ] && [ "$1/chrome/userChrome.css" -ef chrome/userChrome.css ]; }
# Fake addons.mozilla.org: one dummy .xpi per add-on listed in install.sh.
AMO_URL="file://$T/amo"; export AMO_URL
fake_xpi() { mkdir -p "$T/amo/firefox/downloads/latest/$1" && echo "xpi $1" > "$T/amo/firefox/downloads/latest/$1/latest.xpi"; }
sed -n "/^addons='/,/^'/p" install.sh | while read -r slug id; do [ -n "$id" ] && fake_xpi "$slug"; done

# default profile: the single [Install] default wins over legacy Default=1
ini '[Install2656FF1E876E9973]' 'Default=Profiles/aaa.default-release'
./install.sh >/dev/null || fail "install default"
ours "$A" || fail "default profile not linked"
./install.sh >/dev/null || fail "re-install is not idempotent"

# by Name and by folder name
./install.sh default >/dev/null && ours "$B" || fail "install by Name"
./install.sh -u bbb.default >/dev/null || fail "uninstall by folder"
[ -e "$B/user.js" ] || [ -e "$B/chrome" ] && fail "uninstall left files"

# several installs with different defaults: refuse, ask for a profile
ini '[Install1]' 'Default=Profiles/aaa.default-release' '' '[Install2]' 'Default=Profiles/bbb.default'
./install.sh -u >/dev/null 2>&1 && fail "ambiguous default accepted"

# not a profile / unknown name: refuse
./install.sh "$T/notaprofile" >/dev/null 2>&1 && fail "non-profile dir accepted"
./install.sh nope >/dev/null 2>&1 && fail "unknown profile accepted"

# the user's own files are moved to .orig and restored on uninstall
mkdir -p "$B/chrome"; echo mine > "$B/chrome/userChrome.css"; echo 'user_pref("x", 1);' > "$B/user.js"
./install.sh bbb.default </dev/null >/dev/null && ours "$B" || fail "install over user files"
[ "$(cat "$B/chrome/userChrome.css.orig")" = mine ] || fail "css not backed up"
./install.sh bbb.default >/dev/null || fail "re-install with .orig present"
./install.sh -u bbb.default >/dev/null || fail "uninstall with backups"
[ "$(cat "$B/chrome/userChrome.css")" = mine ] && [ "$(cat "$B/user.js")" = 'user_pref("x", 1);' ] || fail "backups not restored"
[ -e "$B/user.js.orig" ] && fail ".orig left behind"

# a user file plus an existing .orig: refuse, write nothing
echo older > "$B/user.js.orig"
./install.sh bbb.default >/dev/null 2>&1 && fail "would overwrite .orig"
[ "$(cat "$B/user.js.orig")" = older ] && [ ! -L "$B/chrome/userChrome.css" ] || fail "partial install"
rm -r "$B/chrome" "$B/user.js" "$B/user.js.orig"

# answering y deletes the backups this run made
echo mine > "$B/user.js"
echo y | ./install.sh bbb.default >/dev/null && [ ! -e "$B/user.js.orig" ] || fail "backup kept after y"
./install.sh -u bbb.default >/dev/null && [ ! -e "$B/user.js" ] || fail "uninstall after deleting backup"

# an identical copy (old copy-style install) is replaced by a link
mkdir -p "$B/chrome"; cp user.js "$B/"; cp chrome/userChrome.css "$B/chrome/"
./install.sh bbb.default >/dev/null && ours "$B" || fail "copy not migrated"

# links made through another path to the repo are still recognised
ln -s "$REPO" "$T/alias"
"$T/alias/install.sh" -u bbb.default >/dev/null && "$T/alias/install.sh" bbb.default >/dev/null || fail "alias install"
./install.sh -u bbb.default >/dev/null && [ ! -e "$B/user.js" ] || fail "uninstall via other path"

# add-ons: each listed one is downloaded once; -u removes only those
C="$FIREFOX_DIR/Profiles/ccc"; mkdir -p "$C/extensions"; touch "$C/prefs.js"
echo own > "$C/extensions/uBlock0@raymondhill.net.xpi"           # user installed it already
rm "$T/amo/firefox/downloads/latest/violentmonkey/latest.xpi"    # download fails
./install.sh "$C" >/dev/null 2>&1 || fail "install with a failed download"
[ -f "$C/extensions/@testpilot-containers.xpi" ] || fail "add-on not downloaded"
[ -e "$C/extensions/{aecec67f-0d10-4fa7-b7c7-609a2db280cf}.xpi" ] && fail "failed download left a file"
fake_xpi violentmonkey; ./install.sh "$C" >/dev/null || fail "re-install"
[ -f "$C/extensions/{aecec67f-0d10-4fa7-b7c7-609a2db280cf}.xpi" ] || fail "failed download not retried"
rm "$C/extensions/@testpilot-containers.xpi"                     # user removed it in Firefox
./install.sh "$C" >/dev/null && [ ! -e "$C/extensions/@testpilot-containers.xpi" ] || fail "removed add-on came back"
./install.sh -u "$C" >/dev/null || fail "uninstall add-ons"
[ "$(ls "$C/extensions")" = uBlock0@raymondhill.net.xpi ] && [ "$(cat "$C/extensions/uBlock0@raymondhill.net.xpi")" = own ] || fail "uninstall touched the user's add-on or left ours"

if command -v shellcheck >/dev/null; then shellcheck install.sh tests/test.sh || fail shellcheck; fi
[ "$fails" -eq 0 ] && echo "PASS"
