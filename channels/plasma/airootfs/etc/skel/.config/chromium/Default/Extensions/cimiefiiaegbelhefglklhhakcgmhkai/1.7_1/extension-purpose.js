/*
    Copyright (C) 2019 Kai Uwe Broulik <kde@privat.broulik.de>

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

let purposeShareMenuId = "purpose_share";

function purposeShare(data) {
    return new Promise((resolve, reject) => {
        sendPortMessageWithReply("purpose", "share", {data}).then((reply) => {
            if (!reply.success) {
                if (!["BUSY", "CANCELED", "INVALID_ARGUMENT"].includes(reply.errorCode)
                    && reply.errorCode !== 1 /*ERR_USER_CANCELED*/) {
                    chrome.notifications.create(null, {
                        type: "basic",
                        title: chrome.i18n.getMessage("purpose_share_failed_title"),
                        message: chrome.i18n.getMessage("purpose_share_failed_text",
                                                        reply.errorMessage || chrome.i18n.getMessage("general_error_unknown")),
                        iconUrl: "icons/document-share-failed.png"
                    });
                }

                reject();
                return;
            }

            let url = reply.response.url;
            if (url) {
                chrome.notifications.create(null, {
                    type: "basic",
                    title: chrome.i18n.getMessage("purpose_share_finished_title"),
                    message: chrome.i18n.getMessage("purpose_share_finished_text", url),
                    iconUrl: "icons/document-share.png"
                });
            }

            resolve();
        });
    });
}

chrome.contextMenus.onClicked.addListener((info) => {
    if (info.menuItemId !== purposeShareMenuId) {
        return;
    }

    let url = info.linkUrl || info.srcUrl || info.pageUrl;
    let selection = info.selectionText;
    if (!url && !selection) {
        return;
    }

    let shareData = {};
    if (selection) {
        shareData.text = selection;
    } else if (url) {
        shareData.url = url;
    }

    // We probably shared the current page, add its title to shareData
    new Promise((resolve, reject) => {
        if (!info.linkUrl && !info.srcUrl && info.pageUrl) {
            chrome.tabs.query({
                // more correct would probably be currentWindow + activeTab
                url: info.pageUrl
            }, (tabs) => {
                if (tabs[0]) {
                    return resolve(tabs[0].title);
                }
                resolve("");
            });
            return;
        }

        resolve("");
    }).then((title) => {
        if (title) {
            shareData.title = title;
        }

        purposeShare(shareData);
    });
});

chrome.contextMenus.create({
    id: purposeShareMenuId,
    contexts: ["link", "page", "image", "audio", "video", "selection"],
    title: chrome.i18n.getMessage("purpose_share")
});

addRuntimeCallback("purpose", "share", (message, sender, action) => {
    return purposeShare(message);
});
