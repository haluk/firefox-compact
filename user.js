// firefox-compact prefs. Linked into the profile by install.sh; Firefox applies them on every start.

// Allow chrome/userChrome.css to load.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Vertical tabs in a collapsed sidebar; expand it with the "Expand sidebar" button or Ctrl+Z.
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.visibility", "always-show");

// Compact density.
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);

// Add-ons that install.sh puts in the profile: start them on the very next launch
// (scan the profile at startup; default 0 waits a launch) and enable them (default 15 leaves them disabled).
user_pref("extensions.startupScanScopes", 1);
user_pref("extensions.autoDisableScopes", 14);

// Less chrome: no bookmarks toolbar, no Firefox View.
user_pref("browser.toolbars.bookmarks.visibility", "never");
user_pref("browser.tabs.firefox-view", false);

// Optional: enforce the toolbar layout (sidebar, back, forward, reload, URL bar, list all tabs, extensions).
// Arrange it once with Customize Toolbar instead; uncomment only if you want it reset on every start,
// which also unpins any add-on buttons you pin. "seen" stops Firefox auto-adding new default buttons.
// user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"urlbar-container\",\"vertical-spacer\",\"alltabs-button\",\"unified-extensions-button\"],\"TabsToolbar\":[],\"vertical-tabs\":[\"tabbrowser-tabs\"],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"fire-button\",\"reset-pbm-toolbar-button\",\"smartwindow-group-tabs-button\",\"ai-window-toggle\",\"developer-button\",\"ipprotection-button\",\"screenshot-button\",\"save-to-pocket-button\",\"firefox-view-button\",\"downloads-button\",\"fxa-toolbar-menu-button\"],\"dirtyAreaCache\":[\"nav-bar\",\"TabsToolbar\",\"vertical-tabs\",\"PersonalToolbar\"],\"currentVersion\":28,\"newElementCount\":0}");
