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

var kdeConnectMenuIdPrefix = "kdeconnect_page_";
var kdeConnectDevices = {};

chrome.contextMenus.onClicked.addListener(function (info) {
    if (!info.menuItemId.startsWith(kdeConnectMenuIdPrefix)) {
        return;
    }

    var deviceId = info.menuItemId.substr(kdeConnectMenuIdPrefix.length);

    var url = info.linkUrl || info.srcUrl || info.pageUrl;
    console.log("Send url", url, "to kdeconnect device", deviceId);
    if (!url) {
        return;
    }

    port.postMessage({
        subsystem: "kdeconnect",
        event: "shareUrl",
        url: url,
        deviceId: deviceId
    });
});

addCallback("kdeconnect", "deviceAdded", function(message) {
    let deviceId = message.id;
    let name = message.name;
    let type = message.type;

    let menuEntryTitle = chrome.i18n.getMessage("kdeconnect_open_device", name);
    let menuId = kdeConnectMenuIdPrefix + deviceId;

    chrome.contextMenus.create({
        id: menuId,
        contexts: ["link", "page", "image", "audio", "video"],
        title: menuEntryTitle,
    });

    kdeConnectDevices[deviceId] = {
        name, type
    };
});

addCallback("kdeconnect", "deviceRemoved", function(message) {
    let deviceId = message.id;

    if (!kdeConnectDevices[deviceId]) {
        return;
    }

    delete kdeConnectDevices[deviceId];
    chrome.contextMenus.remove(kdeConnectMenuIdPrefix + deviceId);
});
