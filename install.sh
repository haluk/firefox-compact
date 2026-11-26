#!/bin/sh
# Symlink this repo's user.js and chrome/userChrome.css into a Firefox profile,
# and add the add-ons below. Existing files are kept as FILE.orig and restored by -u.
# Usage: ./install.sh [-u] [PROFILE]
#   PROFILE  profile name, folder name or path; default: the profile Firefox starts with
#   -u       remove the links and the add-ons this script added
# shellcheck disable=SC3013  # test -ef: supported by bash, dash, busybox and zsh
set -eu

# Add-ons: addons.mozilla.org slug, add-on ID. Each is downloaded once; Firefox starts
# it on the next launch (see extensions.* in user.js) and keeps it updated.
addons='
ublock-origin            uBlock0@raymondhill.net
proton-pass              78272b6fa58f4a1abaac99321d503a20@proton.me
multi-account-containers @testpilot-containers
refined-github-          {a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}
violentmonkey            {aecec67f-0d10-4fa7-b7c7-609a2db280cf}
copy-plaintext           copyplaintext@eros.man
private-relay            private-relay@firefox.com
bonjourr-startpage       {4f391a9e-8717-4ba6-a5b1-488a34931fcb}
zoho-annotator           {d4504156-6a58-4503-86b5-2f9a773844e4}
'
amo="${AMO_URL:-https://addons.mozilla.org}"
repo="$(cd "$(dirname "$0")" && pwd)"
ffdir="$HOME/.mozilla/firefox"
[ "$(uname -s)" = Darwin ] && ffdir="$HOME/Library/Application Support/Firefox"
ffdir="${FIREFOX_DIR:-$ffdir}"
die() { echo "error: $*" >&2; exit 1; }

# profiles.ini -> "name<TAB>path<TAB>Default" per profile, "@install<TAB>path" per install
profiles() {
	f="$ffdir/profiles.ini"
	# installs.ini lists the default profile too; use it when profiles.ini is unreadable (macOS can block it).
	{ [ -f "$f" ] && : <"$f"; } 2>/dev/null || f="$ffdir/installs.ini"
	[ -f "$f" ] || die "no profiles.ini in $ffdir (set FIREFOX_DIR)"
	awk -v base="$ffdir" -v inst="${f##*/}" '
	function out() { if (p != "") print (s ~ /^\[Install/ || inst == "installs.ini" ? "@install" : n) "\t" (r == "0" || p ~ /^\// ? p : base "/" p) "\t" d; n = p = d = ""; r = 1 }
	{ sub(/\r$/, "") }
	/^\[/ { out(); s = $0; next }
	/^Name=/ { n = substr($0, 6) }
	/^Path=/ { p = substr($0, 6) }
	/^IsRelative=/ { r = substr($0, 12) }
	/^Default=/ { if (s ~ /^\[Install/ || inst == "installs.ini") p = substr($0, 9); else d = substr($0, 9) }
	END { out() }' "$f"
}

pick() {
	list="$(profiles)"
	case "$1" in
	"") p="$(printf '%s\n' "$list" | awk -F '\t' '$1 == "@install" { print $2 }' | sort -u)"
	    [ -n "$p" ] || p="$(printf '%s\n' "$list" | awk -F '\t' '$1 != "@install" && $3 == "1" { print $2 }')" ;;
	/*) p="$1" ;;
	*)  p="$(printf '%s\n' "$list" | awk -F '\t' -v a="$1" '$1 != "@install" { f = $2; sub(/.*\//, "", f); if ($1 == a || f == a) print $2 }')" ;;
	esac
	if [ -z "$p" ] || [ "$(printf '%s\n' "$p" | wc -l)" -ne 1 ] || [ ! -f "$p/prefs.js" ]; then
		echo "error: no single Firefox profile matches '${1:-default}'. Pass one of:" >&2
		printf '%s\n' "$list" | awk -F '\t' '$1 != "@install" { print "  " $1 "\t" $2 }' >&2
		exit 1
	fi
	echo "$p"
}

# Ours: a link to the repo file, or an identical copy. Anything else is the user's:
# install moves it to FILE.orig, uninstall moves it back.
taken() { [ -e "$1" ] || [ -L "$1" ]; }
ours() { [ "$2" -ef "$1" ] || { [ -f "$2" ] && [ ! -L "$2" ] && cmp -s "$1" "$2"; }; }
check() { ! taken "$2" || ours "$@" || ! taken "$2.orig" || die "$2 and $2.orig both exist; move one away first"; }
link() {
	[ -L "$2" ] && [ "$2" -ef "$1" ] && return
	if taken "$2" && ! ours "$@"; then
		mv "$2" "$2.orig"; echo "moved your $2 to $2.orig"
		backups="$backups$2.orig
"
	fi
	rm -f "$2"; ln -s "$1" "$2"; echo "linked $2"
}
remove() {
	if ours "$@"; then rm "$2"; echo "removed $2"; done=1
	elif taken "$2"; then echo "kept $2 (not ours)"; fi
	if ! taken "$2" && taken "$2.orig"; then mv "$2.orig" "$2"; echo "restored $2"; done=1; fi
}

# Added add-on IDs are recorded, so a re-run never re-adds one you removed in Firefox,
# one you installed yourself is left alone, and -u removes only ours.
add_addons() {
	mkdir -p "$prof/extensions"; touch "$rec"
	printf '%s' "$addons" | while read -r slug id; do
		xpi="$prof/extensions/$id.xpi"
		[ -n "$id" ] && ! grep -qxF "$id" "$rec" && [ ! -e "$xpi" ] || continue
		if curl -fsSL -o "$xpi.part" "$amo/firefox/downloads/latest/$slug/latest.xpi"; then
			mv "$xpi.part" "$xpi"; echo "$id" >> "$rec"; echo "added add-on $slug"
		else
			rm -f "$xpi.part"; echo "warning: could not download add-on $slug; re-run to retry" >&2
		fi
	done
}
remove_addons() {
	[ -f "$rec" ] || return 0
	while read -r id; do
		rm -f "$prof/extensions/$id.xpi"
		echo "removed add-on $(printf '%s' "$addons" | awk -v i="$id" '$2 == i { n = $1 } END { print (n != "" ? n : i) }')"
	done < "$rec"
	rm "$rec"; done=1
}

uninstall=0
[ "${1:-}" = -u ] && { uninstall=1; shift; }
prof="$(pick "${1:-}")"
ujs="$repo/user.js"; css="$repo/chrome/userChrome.css"; rec="$prof/firefox-compact-addons"

if [ "$uninstall" = 1 ]; then
	done=0
	remove "$ujs" "$prof/user.js"
	remove "$css" "$prof/chrome/userChrome.css"
	remove_addons
	rmdir "$prof/chrome" "$prof/extensions" 2>/dev/null || true
	if [ "$done" = 1 ]; then echo "note: prefs already applied stay in prefs.js; see README to reset them"
	else echo "nothing to remove in $prof"; fi
else
	check "$ujs" "$prof/user.js"
	check "$css" "$prof/chrome/userChrome.css"
	mkdir -p "$prof/chrome"
	backups=""
	link "$ujs" "$prof/user.js"
	link "$css" "$prof/chrome/userChrome.css"
	add_addons
	if [ -n "$backups" ]; then
		printf 'Delete these backups? Then -u cannot restore your old files. [y/N] '
		read -r answer || answer=""
		case "$answer" in [yY]*)
			printf '%s' "$backups" | while IFS= read -r f; do rm -f -- "$f"; echo "deleted $f"; done ;;
		*) echo "kept backups; -u restores them" ;;
		esac
	fi
	echo "restart Firefox to apply"
fi
