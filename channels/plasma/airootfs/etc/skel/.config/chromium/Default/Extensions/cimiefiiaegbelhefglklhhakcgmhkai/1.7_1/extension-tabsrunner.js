/*
    Copyright (C) 2017 Kai Uwe Broulik <kde@privat.broulik.de>

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 3 of
    the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

addCallback("tabsrunner", "activate", function (message) {
    var tabId = message.tabId;

    console.log("Tabs Runner requested to activate tab with id", tabId);

    raiseTab(tabId);
});

addCallback("tabsrunner", "setMuted", function (message) {

    var tabId = message.tabId;
    var muted = message.muted;

    chrome.tabs.update(tabId, {muted: muted}, function (tab) {

        if (chrome.runtime.lastError || !tab) { // this "lastError" stuff feels so archaic
            // failed to mute/unmute
            return;
        }
    });

});

// only forward certain tab properties back to our host
var whitelistedTabProperties = [
    "id", "active", "audible", "favIconUrl", "incognito", "title", "url", "mutedInfo"
];

// FIXME We really should enforce some kind of security policy, so only e.g. plasmashell and krunner
// may access your tabs
addCallback("tabsrunner", "getTabs", function (message) {
    chrome.tabs.query({}, function (tabs) {
        // remove incognito tabs and properties not in whitelist
        var filteredTabs = tabs;

        // Firefox before 67 runs extensions in incognito by default
        // but we keep running after an update, so exclude those tabs for it
        if (IS_FIREFOX) {
            filteredTabs = filteredTabs.filter(function (tab) {
                return !tab.incognito;
            });
        }

        var filteredTabs = filterArrayObjects(filteredTabs, whitelistedTabProperties);

        // Shared between the callbacks
        var total = filteredTabs.length;

        var sendTabsIfComplete = function() {
            if (--total > 0) {
                return;
            }

            port.postMessage({
                subsystem: "tabsrunner",
                event: "gotTabs",
                tabs: filteredTabs
            });
        };

        for (let tabIndex in filteredTabs) {
            let currentIndex = tabIndex; // Not shared
            var favIconUrl = filteredTabs[tabIndex].favIconUrl;

            if (!favIconUrl) {
                sendTabsIfComplete();
            } else if (favIconUrl.match(/^data:image/)) {
                // Already a data URL
                filteredTabs[currentIndex].favIconData = favIconUrl;
                filteredTabs[currentIndex].favIconUrl = "";
                sendTabsIfComplete();
            } else {
                // Send a request to fill the cache (=no timeout)
                let xhrForCache = new XMLHttpRequest();
                xhrForCache.open("GET", favIconUrl);
                xhrForCache.send();

                // Try to fetch from (hopefully) the cache (100ms timeout)
                let xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
                    if (xhr.readyState != 4) {
                        return;
                    }

                    if (!xhr.response) {
                        filteredTabs[currentIndex].favIconData = "";
                        sendTabsIfComplete();
                        return;
                    }

                    var reader = new FileReader();
                    reader.onloadend = function() {
                        filteredTabs[currentIndex].favIconData = reader.result;
                        sendTabsIfComplete();
                    }
                    reader.readAsDataURL(xhr.response);
                };
                xhr.open('GET', favIconUrl);
                xhr.responseType = 'blob';
                xhr.timeout = 100;
                xhr.send();
            }
        }
    });
});
