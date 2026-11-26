# firefox-compact

A compact, Helium-inspired Firefox layout: tabs live in a slim vertical sidebar,
one thin bar holds the essentials, and everything else is a menu away.

```
┌──┬──────────────────────────────────────────┐
│◉ │ ▯ ‹ › ⟳ [ example.com            ] ⌄ 🧩 ☰│  ← one ~32px bar
│◉ ├──────────────────────────────────────────┤
│◉ │              page content                │
│+ │                                          │
└──┴──────────────────────────────────────────┘
 ↑ icons only; expands with tab titles via the sidebar button or Ctrl+Z
```

Two files do the work: `user.js` (native prefs: vertical tabs, compact density)
and `chrome/userChrome.css` (sizing). Requires Firefox 136+; tested on 161, macOS.

## Install

```sh
./install.sh              # profile Firefox starts with; or: ./install.sh <name|folder|path>
./install.sh -u           # remove the links and the add-ons it added
```

The script symlinks both files into the profile, so `git pull` plus a Firefox
restart updates everything. If the profile already has its own `user.js` or
`userChrome.css`, it is moved to `user.js.orig` / `userChrome.css.orig` and put
back by `./install.sh -u`. The script then asks whether to delete those backups
(default: keep). Without them, `-u` cannot restore your old files.
Run `tests/test.sh` after changing the script (it uses a fake profile).

Removing the links doesn't undo prefs Firefox already applied. Reset them in
`about:config` (search `sidebar.`, `browser.uidensity`) or via *Settings →
General → Browser layout*. Also reset `extensions.autoDisableScopes` and
`extensions.startupScanScopes`: while they are set, Firefox enables any add-on
another program puts in your profile.

## Customize

Edit `user.js` or `chrome/userChrome.css`, then restart Firefox. Arrange the
toolbar once with *Customize Toolbar*; to enforce a layout on every start
instead, uncomment `browser.uiCustomization.state` in `user.js`.

## Add-ons

`install.sh` downloads these from addons.mozilla.org into the profile. Firefox
starts them on its next launch and keeps them updated. Some add-ons (uBlock Origin, Containers) pin themselves
to the toolbar; right-click → *Unpin from Toolbar*. Each is added once: one
you remove in Firefox stays removed, one you already had is left alone, and `-u`
removes only the ones it added. Edit the list at the top of `install.sh`.

- [uBlock Origin](https://addons.mozilla.org/firefox/addon/ublock-origin/): content blocker.
  In its settings, enable the *Annoyances* lists (cookie banners, pop-ups) and
  *AdGuard URL Tracking Protection* (strips tracking parameters).
- [Proton Pass](https://addons.mozilla.org/firefox/addon/proton-pass/): password manager.
- [Multi-Account Containers](https://addons.mozilla.org/firefox/addon/multi-account-containers/): separate work and personal logins in one window.
- [Refined GitHub](https://addons.mozilla.org/firefox/addon/refined-github-/): many small GitHub improvements.
- [Violentmonkey](https://addons.mozilla.org/firefox/addon/violentmonkey/): userscripts. Keep your own in `userscripts/`.
- [Copy PlainText](https://addons.mozilla.org/firefox/addon/copy-plaintext/): copy styled text as plain text.
- [Firefox Relay](https://addons.mozilla.org/firefox/addon/private-relay/): email masks to hide your real address.
- [Bonjourr](https://addons.mozilla.org/firefox/addon/bonjourr-startpage/): minimalist new tab page.
- [Zoho Annotator](https://addons.mozilla.org/firefox/addon/zoho-annotator/): highlight and annotate pages.

## Everyday use

- **Search tabs**: *List all tabs* (⌄) → *Search tabs*, or type `% term` in the URL bar.
- **Paste without formatting**: ⌘⌥⇧V / Ctrl+Shift+V.
- **Media**: Firefox media also shows in macOS *Now Playing*, responds to media keys,
  and offers Picture-in-Picture.
- **Split view**: right-click a tab → *Add Split View*, or right-click a link →
  *Open Link in Split View*, to see two pages side by side.
- **Link preview**: click and hold a link (or right-click it) for a card with its
  description and reading time.
- **Tab groups**: right-click a tab → *Add tab to new group*; groups can be saved and closed.
- **Keyword searches**: bookmark a search URL with `%s` in place of the query and
  give it a keyword, e.g. `ax` → `https://arxiv.org/search/?query=%s&searchtype=all`.
  Then type `ax diffusion` in the URL bar.
