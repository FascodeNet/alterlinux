/*
    Copyright (C) 2017 Kai Uwe Broulik <kde@privat.broulik.de>
    Copyright (C) 2018 David Edmundson <davidedmundson@kde.org>

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

var callbacks = {};

// from https://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript
function generateGuid() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
        return v.toString(16);
    });
}

function addCallback(subsystem, action, callback)
{
    if (!callbacks[subsystem]) {
        callbacks[subsystem] = {};
    }
    callbacks[subsystem][action] = callback;
}

function executeScript(script) {
    var element = document.createElement('script');
    element.innerHTML = '('+ script +')();';
    (document.body || document.head || document.documentElement).appendChild(element);
    // We need to remove the script tag after inserting or else websites relying on the order of items in
    // document.getElementsByTagName("script") will break (looking at you, Google Hangouts)
    element.parentNode.removeChild(element);
}

chrome.runtime.onMessage.addListener(function (message, sender) {
    // TODO do something with sender (check privilige or whatever)

    var subsystem = message.subsystem;
    var action = message.action;

    if (!subsystem || !action) {
        return;
    }

    if (callbacks[subsystem] && callbacks[subsystem][action]) {
        callbacks[subsystem][action](message.payload);
    }
});

SettingsUtils.get().then((items) => {
    if (items.breezeScrollBars.enabled) {
        loadBreezeScrollBars();
    }

    const mpris = items.mpris;
    if (mpris.enabled) {
        const origin = window.location.origin;

        const websiteSettings = mpris.websiteSettings || {};

        let mprisAllowed = true;
        if (typeof MPRIS_WEBSITE_SETTINGS[origin] === "boolean") {
            mprisAllowed = MPRIS_WEBSITE_SETTINGS[origin];
        }
        if (typeof websiteSettings[origin] === "boolean") {
            mprisAllowed = websiteSettings[origin];
        }

        if (mprisAllowed) {
            loadMpris();
            if (items.mprisMediaSessions.enabled) {
                loadMediaSessionsShim();
            }
        }
    }

    if (items.purpose.enabled) {
        sendMessage("settings", "getSubsystemStatus").then((status) => {
            if (status && status.purpose) {
                loadPurpose();
            }
        });
    }
});

// BREEZE SCROLL BARS
// ------------------------------------------------------------------------
//
function loadBreezeScrollBars() {
    if (IS_FIREFOX) {
        return;
    }

    if (!document.head) {
        return;
    }

    // You cannot access cssRules for <link rel="stylesheet" ..> on a different domain.
    // Since our chrome-extension:// URL for a stylesheet would be, this can
    // lead to problems in e.g modernizr, so include the <style> inline instead.
    // "Failed to read the 'cssRules' property from 'CSSStyleSheet': Cannot access rules"
    var styleTag = document.createElement("style");
    styleTag.appendChild(document.createTextNode(`
html::-webkit-scrollbar {
    /* we'll add padding as "border" in the thumb*/
    height: 20px;
    width: 20px;
    background: white;
}

html::-webkit-scrollbar-track {
    border-radius: 20px;
    border: 7px solid white; /* FIXME why doesn't "transparent" work here?! */
    background-color: white;
    width: 6px !important; /* 20px scrollbar - 2 * 7px border */
    box-sizing: content-box;
}
html::-webkit-scrollbar-track:hover {
    background-color: #BFC0C2;
}

html::-webkit-scrollbar-thumb {
    background-color: #3DAEE9; /* default blue breeze color */
    border: 7px solid transparent;
    border-radius: 20px;
    background-clip: content-box;
    width: 6px !important; /* 20px scrollbar - 2 * 7px border */
    box-sizing: content-box;
    min-height: 30px;
}
html::-webkit-scrollbar-thumb:window-inactive {
   background-color: #949699; /* when window is inactive it's gray */
}
html::-webkit-scrollbar-thumb:hover {
    background-color: #93CEE9; /* hovered is a lighter blue */
}

html::-webkit-scrollbar-corner {
    background-color: white; /* FIXME why doesn't "transparent" work here?! */
}
    `));

    document.head.appendChild(styleTag);
}


// MPRIS
// ------------------------------------------------------------------------
//

// also give the function a "random" name as we have to have it in global scope to be able
// to invoke callbacks from outside, UUID might start with a number, so prepend something
const mediaSessionsClassName = "f" + generateGuid().replace(/-/g, "");

var activePlayer;
// When a player has no duration yet, we'll wait for it becoming known
// to determine whether to ignore it (short sound) or make it active
var pendingActivePlayer;
var playerMetadata = {};
var playerCallbacks = [];

// Playback state communicated via media sessions api
var playerPlaybackState = "";

var players = [];

var pendingSeekingUpdate = 0;

var titleTagObserver = null;
var oldPageTitle = "";

addCallback("mpris", "play", function () {
    playerPlay();
});

addCallback("mpris", "pause", function () {
    playerPause();
});

addCallback("mpris", "playPause", function () {
    if (activePlayer) {
        if (activePlayer.paused) { // TODO take into account media sessions playback state
            playerPlay();
        } else {
            playerPause();
        }
    }
});

addCallback("mpris", "stop", function () {
    // When available, use the "stop" media sessions action
    if (playerCallbacks.indexOf("stop") > -1) {
        executeScript(`
            function() {
                try {
                    ${mediaSessionsClassName}.executeCallback("stop");
                } catch (e) {
                    console.warn("Exception executing 'stop' media sessions callback", e);
                }
            }
        `);
        return;
    }

    // otherwise since there's no "stop" on the player, simulate it be rewinding and reloading
    if (activePlayer) {
        activePlayer.pause();
        activePlayer.currentTime = 0;
        // calling load() now as is suggested in some "how to fake video Stop" code snippets
        // utterly breaks stremaing sites
        //activePlayer.load();

        // needs to be delayed slightly otherwise we pause(), then send "stopped", and only after that
        // the "paused" signal is handled and we end up in Paused instead of Stopped state
        setTimeout(function() {
            sendMessage("mpris", "stopped");
        }, 1);
        return;
    }
});

addCallback("mpris", "next", function () {
    if (playerCallbacks.indexOf("nexttrack") > -1) {
        executeScript(`
            function() {
                try {
                    ${mediaSessionsClassName}.executeCallback("nexttrack");
                } catch (e) {
                    console.warn("Exception executing 'nexttrack' media sessions callback", e);
                }
            }
        `);
    }
});

addCallback("mpris", "previous", function () {
    if (playerCallbacks.indexOf("previoustrack") > -1) {
        executeScript(`
            function() {
                try {
                    ${mediaSessionsClassName}.executeCallback("previoustrack");
                } catch (e) {
                    console.warn("Exception executing 'previoustrack' media sessions callback", e);
                }
            }
        `);
    }
});

addCallback("mpris", "setFullscreen", (message) => {
    if (activePlayer) {
        if (message.fullscreen) {
            activePlayer.requestFullscreen();
        } else {
            document.exitFullscreen();
        }
    }
});

addCallback("mpris", "setPosition", function (message) {
    if (activePlayer) {
        activePlayer.currentTime = message.position;
    }
});

addCallback("mpris", "setPlaybackRate", function (message) {
    if (activePlayer) {
        activePlayer.playbackRate = message.playbackRate;
    }
});

addCallback("mpris", "setVolume", function (message) {
    if (activePlayer) {
        activePlayer.volume = message.volume;
        activePlayer.muted = (message.volume == 0.0);
    }
});

addCallback("mpris", "setLoop", function (message) {
    if (activePlayer) {
        activePlayer.loop = message.loop;
    }
});

addCallback("mpris", "identify", function (message) {
    if (activePlayer) {
        // We don't have a dedicated "send player info" callback, so we instead send a "playing"
        // and if we're paused, we'll send a "paused" event right after
        // TODO figure out a way how to add this to the host without breaking compat

        var paused = activePlayer.paused;
        playerPlaying(activePlayer);
        if (paused) {
            playerPaused(activePlayer);
        }
    }
});

function playerPlaying(player) {
    setPlayerActive(player);
}

function playerPaused(player) {
    sendPlayerInfo(player, "paused");
}

function setPlayerActive(player) {
    if (isNaN(player.duration)) {
        // Ignore this player for now until we know a duration
        // In durationchange event handler we'll check for this and end up here again
        pendingActivePlayer = player;
        return;
    }

    pendingActivePlayer = undefined;

    // Ignore short sounds, they are most likely a chat notification sound
    // A stream has a duration of Infinity
    // Note that "NaN" is also not finite but we already returned earlier for that
    if (isFinite(player.duration) && player.duration > 0 && player.duration < 8) {
        return;
    }

    activePlayer = player;

    // when playback starts, send along metadata
    // a website might have set Media Sessions metadata prior to playing
    // and then we would have ignored the metadata signal because there was no player
    sendMessage("mpris", "playing", {
        mediaSrc: player.src,
        pageTitle: document.title,
        duration: player.duration,
        currentTime: player.currentTime,
        playbackRate: player.playbackRate,
        volume: player.volume,
        muted: player.muted,
        loop: player.loop,
        metadata: playerMetadata,
        callbacks: playerCallbacks,
        fullscreen: document.fullscreenElement !== null,
        canSetFullscreen: player.tagName.toLowerCase() === "video"
    });

    if (!titleTagObserver) {

        // Observe changes to the <title> tag in case it is updated after the player has started playing
        let titleTag = document.querySelector("head > title");
        if (titleTag) {
            oldPageTitle = titleTag.innerText;

            titleTagObserver = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                    const pageTitle = mutation.target.textContent;
                    if (pageTitle && oldPageTitle !== pageTitle) {
                        sendMessage("mpris", "titlechange", {
                            pageTitle: pageTitle
                        });
                    }
                    oldPageTitle = pageTitle;
                });
            });

            titleTagObserver.observe(titleTag, {
                childList: true, // text content is technically a child node
                subtree: true,
                characterData: true
            });
        }
    }
}

function sendPlayerGone() {
    var playerIdx = players.indexOf(activePlayer);
    if (playerIdx > -1) {
        players.splice(playerIdx, 1);
    }

    activePlayer = undefined;
    pendingActivePlayer = undefined;
    playerMetadata = {};
    playerCallbacks = [];
    sendMessage("mpris", "gone");

    if (titleTagObserver) {
        titleTagObserver.disconnect();
        titleTagObserver = null;
    }
}

function sendPlayerInfo(player, event, payload) {
    if (player != activePlayer) {
        return;
    }

    sendMessage("mpris", event, payload);
}

function registerPlayer(player) {
    if (players.indexOf(player) > -1) {
        //console.log("Already know", player);
        return;
    }

    // auto-playing player, become active right away
    if (!player.paused) {
        playerPlaying(player);
    }
    player.addEventListener("play", function () {
        playerPlaying(player);
    });

    player.addEventListener("pause", function () {
        playerPaused(player);
    });

    // what about "stalled" event?
    player.addEventListener("waiting", function () {
        sendPlayerInfo(player, "waiting");
    });

    // playlist is now empty or being reloaded, stop player
    // e.g. when using Ajax page navigation and the user nagivated away
    player.addEventListener("emptied", function () {
        // When the player is emptied but the website tells us it's just "paused"
        // keep it around (Bug 402324: Soundcloud does this)
        if (player === activePlayer && playerPlaybackState === "paused") {
            return;
        }

        // could have its own signal but for compat it's easier just to pretend to have stopped
        sendPlayerInfo(player, "stopped");
    });

    // opposite of "waiting", we finished buffering enough
    // only if we are playing, though, should we set playback state back to playing
    player.addEventListener("canplay", function () {
        if (!player.paused) {
            sendPlayerInfo(player, "canplay");
        }
    });

    player.addEventListener("timeupdate", function () {
        sendPlayerInfo(player, "timeupdate", {
            currentTime: player.currentTime
        });
    });

    player.addEventListener("ratechange", function () {
        sendPlayerInfo(player, "ratechange", {
            playbackRate: player.playbackRate
        });
    });

    // TODO use player.seekable for determining whether we can seek?
    player.addEventListener("durationchange", function () {
        // Deferred active due to unknown duration
        if (pendingActivePlayer == player) {
            setPlayerActive(pendingActivePlayer);
            return;
        }

        sendPlayerInfo(player, "duration", {
            duration: player.duration
        });
    });

    player.addEventListener("seeking", function () {
        if (pendingSeekingUpdate) {
            return;
        }

        // Compress "seeking" signals, this is invoked continuously as the user drags the slider
        pendingSeekingUpdate = setTimeout(function() {
            pendingSeekingUpdate = 0;
        }, 250);

        sendPlayerInfo(player, "seeking", {
            currentTime: player.currentTime
        });
    });

    player.addEventListener("seeked", function () {
        sendPlayerInfo(player, "seeked", {
            currentTime: player.currentTime
        });
    });

    player.addEventListener("volumechange", function () {
        sendPlayerInfo(player, "volumechange", {
            volume: player.volume,
            muted: player.muted
        });
    });

    players.push(player);
}

function registerAllPlayers() {
    var players = document.querySelectorAll("video,audio");
    players.forEach(registerPlayer);
}

function playerPlay() {
    // if a media sessions callback is registered, it takes precedence over us manually messing with the player
    if (playerCallbacks.indexOf("play") > -1) {
        executeScript(`
            function() {
                try {
                    ${mediaSessionsClassName}.executeCallback("play");
                } catch (e) {
                    console.warn("Exception executing 'play' media sessions callback", e);
                }
            }
        `);
    } else if (activePlayer) {
        activePlayer.play();
    }
}

function playerPause() {
    if (playerCallbacks.indexOf("pause") > -1) {
        executeScript(`
            function() {
                try {
                    ${mediaSessionsClassName}.executeCallback("pause");
                } catch (e) {
                    console.warn("Exception executing 'pause' media sessions callback", e);
                }
            }
        `);
    } else if (activePlayer) {
        activePlayer.pause();
    }
}

function loadMpris() {
    // TODO figure out somehow when a <video> tag is added dynamically and autoplays
    // as can happen on Ajax-heavy pages like YouTube
    // could also be done if we just look for the "audio playing in this tab" and only then check for player?
    // cf. "checkPlayer" event above

    var observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            mutation.addedNodes.forEach(function (node) {
                if (typeof node.matches !== "function" || typeof node.querySelectorAll !== "function") {
                    return;
                }

                // Check whether the node itself or any of its children is a player
                var players = Array.from(node.querySelectorAll("video,audio"));
                if (node.matches("video,audio")) {
                    players.unshift(node);
                }

                players.forEach(function (player) {
                    registerPlayer(player);
                });
            });

            mutation.removedNodes.forEach(function (node) {
                if (typeof node.matches !== "function" || typeof node.querySelectorAll !== "function") {
                    return;
                }

                // Check whether the node itself or any of its children is the current player
                var players = Array.from(node.querySelectorAll("video,audio"));
                if (node.matches("video,audio")) {
                    players.unshift(node);
                }

                players.forEach(function (player) {
                    if (player == activePlayer) {
                        // If the player is still in the visible DOM, don't consider it gone
                        if (document.body.contains(player)) {
                            return; // continue
                        }

                        sendPlayerGone();
                        return;
                    }
                });
            });
        });
    });

    observer.observe(document, {
        childList: true,
        subtree: true
    });

    window.addEventListener("beforeunload", function () {
        // about to navigate to a different page, tell our extension that the player will be gone shortly
        // we listen for tab closed in the extension but we don't for navigating away as URL change doesn't
        // neccesarily mean a navigation but beforeunload *should* be the thing we want
        sendPlayerGone();
    });

    // In some cases DOMContentLoaded won't fire, e.g. when watching a video file directly in the browser
    // it generates a "video player" page for you but won't fire the event
    registerAllPlayers();

    document.addEventListener("DOMContentLoaded", function() {
        registerAllPlayers();
    });

    document.addEventListener("fullscreenchange", () => {
        if (activePlayer) {
            sendPlayerInfo(activePlayer, "fullscreenchange", {
                fullscreen: document.fullscreenElement !== null
            });
        }
    });
}

// This adds a shim for the Chrome media sessions API which is currently only supported on Android
// Documentation: https://developers.google.com/web/updates/2017/02/media-session
// Try it here: https://googlechrome.github.io/samples/media-session/video.html

// Bug 379087: Only inject this stuff if we're a proper HTML page
// otherwise we might end up messing up XML stuff
// only if our documentElement is a "html" tag we'll do it
// the rest is only set up in DOMContentLoaded which is only executed for proper pages anyway

// tagName always returned "HTML" for me but I wouldn't trust it always being uppercase
function loadMediaSessionsShim() {
    if (document.documentElement.tagName.toLowerCase() === "html") {

        window.addEventListener("pbiMprisMessage", (e) => {
            let data = e.detail || {};

            let action = data.action;
            let payload = data.payload;

            switch (action) {
            case "metadata":
                playerMetadata = {};

                if (typeof payload !== "object") {
                    return;
                }

                playerMetadata = payload;
                sendMessage("mpris", "metadata", payload);

                return;

            case "playbackState":
                if (!["none", "paused", "playing"].includes(payload)) {
                    return;
                }

                playerPlaybackState = payload;

                if (!activePlayer) {
                    return;
                }

                if (playerPlaybackState === "playing") {
                    playerPlaying(activePlayer);
                } else if (playerPlaybackState === "paused") {
                    playerPaused(activePlayer);
                }

                return;

            case "callbacks":
                if (Array.isArray(payload)) {
                    playerCallbacks = payload;
                } else {
                    playerCallbacks = [];
                }
                sendMessage("mpris", "callbacks", playerCallbacks);

                return;
            }
        });

        executeScript(`
            function() {
                ${mediaSessionsClassName} = function() {};
                ${mediaSessionsClassName}.callbacks = {};
                ${mediaSessionsClassName}.metadata = null;
                ${mediaSessionsClassName}.playbackState = "none";
                ${mediaSessionsClassName}.sendMessage = function(action, payload) {
                    let event = new CustomEvent("pbiMprisMessage", {
                        detail: {
                            action: action,
                            payload: payload
                        }
                    });
                    window.dispatchEvent(event);
                };
                ${mediaSessionsClassName}.executeCallback = function (action) {
                    let details = {
                        action: action
                        // for seekforward, seekbackward, seekto there's additional information one would need to add
                    };
                    this.callbacks[action](details);
                };

                if (!navigator.mediaSession) {
                    navigator.mediaSession = {};
                }

                var noop = function() { };

                var oldSetActionHandler = navigator.mediaSession.setActionHandler || noop;
                navigator.mediaSession.setActionHandler = function (name, cb) {
                    if (cb) {
                        ${mediaSessionsClassName}.callbacks[name] = cb;
                    } else {
                        delete ${mediaSessionsClassName}.callbacks[name];
                    }
                    ${mediaSessionsClassName}.sendMessage("callbacks", Object.keys(${mediaSessionsClassName}.callbacks));

                    // Call the original native implementation
                    // "call()" is needed as the real setActionHandler is a class member
                    // and calling it directly is illegal as it lacks the context
                    // This may throw for unsupported actions but we registered the callback
                    // ourselves before
                    return oldSetActionHandler.call(navigator.mediaSession, name, cb);
                };

                Object.defineProperty(navigator.mediaSession, "metadata", {
                    get: function() { return ${mediaSessionsClassName}.metadata; },
                    set: function(newValue) {
                        ${mediaSessionsClassName}.metadata = newValue;

                        // MediaMetadata is not a regular Object so we cannot just JSON.stringify it
                        var newMetadata = {};
                        if (newValue) {
                            var keys = Object.getOwnPropertyNames(Object.getPrototypeOf(newValue));

                            keys.forEach(function (key) {
                                var value = newValue[key];
                                if (typeof value === "function") {
                                    return; // continue
                                }
                                newMetadata[key] = newValue[key];
                            });
                        }

                        ${mediaSessionsClassName}.sendMessage("metadata", newMetadata);
                    }
                });
                Object.defineProperty(navigator.mediaSession, "playbackState", {
                    get: function() { return ${mediaSessionsClassName}.playbackState; },
                    set: function(newValue) {
                        ${mediaSessionsClassName}.playbackState = newValue;
                        ${mediaSessionsClassName}.sendMessage("playbackState", newValue);
                    }
                });

                if (!window.MediaMetadata) {
                    window.MediaMetadata = function (data) {
                        Object.assign(this, data);
                    };
                    window.MediaMetadata.prototype.title = "";
                    window.MediaMetadata.prototype.artist = "";
                    window.MediaMetadata.prototype.album = "";
                    window.MediaMetadata.prototype.artwork = [];
                }
            }
        `);

        // here we replace the document.createElement function with our own so we can detect
        // when an <audio> tag is created that is not added to the DOM which most pages do
        // while a <video> tag typically ends up being displayed to the user, audio is not.
        // HACK We cannot really pass variables from the page's scope to our content-script's scope
        // so we just blatantly insert the <audio> tag in the DOM and pick it up through our regular
        // mechanism. Let's see how this goes :D

        // HACK When removing a media object from DOM it is paused, so what we do here is once the
        // player loaded some data we add it (doesn't work earlier since it cannot pause when
        // there's nothing loaded to pause) to the DOM and before we remove it, we note down that
        // we will now get a paused event because of that. When we get it, we just play() the player
        // so it continues playing :-)
        const addPlayerToDomEvadingAutoPlayBlocking = `
            player.registerInDom = () => {
                player.pausedBecauseOfDomRemoval = true;
                player.removeEventListener("play", player.registerInDom);

                // If it is already in DOM by the time it starts playing, we don't need to do anything
                if (document.body && document.body.contains(player)) {
                    delete player.pausedBecauseOfDomRemoval;
                    player.removeEventListener("pause", player.replayAfterRemoval);
                } else {
                    (document.head || document.documentElement).appendChild(player);
                    player.parentNode.removeChild(player);
                }
            };

            player.replayAfterRemoval = () => {
                if (player.pausedBecauseOfDomRemoval === true) {
                    delete player.pausedBecauseOfDomRemoval;
                    player.removeEventListener("pause", player.replyAfterRemoval);

                    player.play();
                }
            };

            player.addEventListener("play", player.registerInDom);
            player.addEventListener("pause", player.replayAfterRemoval);
        `;

        executeScript(`function() {
                var oldCreateElement = Document.prototype.createElement;
                Document.prototype.createElement = function() {
                    var createdTag = oldCreateElement.apply(this, arguments);

                    var tagName = arguments[0];

                    if (typeof tagName === "string") {
                        if (tagName.toLowerCase() === "audio") {
                            const player = createdTag;
                            ${addPlayerToDomEvadingAutoPlayBlocking}
                        } else if (tagName.toLowerCase() === "video") {
                            (document.head || document.documentElement).appendChild(createdTag);
                            createdTag.parentNode.removeChild(createdTag);
                        }
                    }

                    return createdTag;
                };
            }
        `);

        // We also briefly add items created as new Audio() to the DOM so we can control it
        // similar to the document.createElement hack above since we cannot share variables
        // between the actual website and the background script despite them sharing the same DOM

        if (IS_FIREFOX) {
            // Firefox enforces Content-Security-Policy also for scripts injected by the content-script
            // This causes our executeScript calls to fail for pages like Nextcloud
            // It also doesn't seem to have the aggressive autoplay prevention Chrome has,
            // so the horrible replyAfterRemoval hack from above isn't copied into this
            // See Bug 411148: Music playing from the ownCloud Music app does not show up
            var oldAudio = window.Audio;
            exportFunction(function(...args) {
                const player = new oldAudio(...args);
                eval(addPlayerToDomEvadingAutoPlayBlocking);
                return player;
            }, window, {defineAs: "Audio"});
        } else {
            executeScript(`function() {
                var oldAudio = window.Audio;
                window.Audio = function (...args) {
                    const player = new oldAudio(...args);
                    ${addPlayerToDomEvadingAutoPlayBlocking}
                    return player;
                };
            }`);
        }
    }
}

// PURPOSE / WEB SHARE API
// ------------------------------------------------------------------------
//
const purposeTransferClassName = "p" + generateGuid().replace(/-/g, "");

var purposeLoaded = false;
function loadPurpose() {
    if (purposeLoaded) {
        return;
    }

    purposeLoaded = true;

    // navigator.share must only be defined in secure (https) context
    if (!window.isSecureContext) {
        return;
    }

     window.addEventListener("pbiPurposeMessage", (e) => {
        const data = e.detail || {};

        const action = data.action;
        const payload = data.payload;

        if (action !== "share") {
            return;
        }

        sendMessage("purpose", "share", payload).then((response) => {
            executeScript(`
                function() {
                    ${purposeTransferClassName}.pendingResolve();
                }
            `);
        }, (err) => {
            // Deliberately not giving any more details about why it got rejected
            executeScript(`
                function() {
                    ${purposeTransferClassName}.pendingReject(new DOMException("Share request aborted", "AbortError"));
                }
            `);
        }).finally(() => {
            executeScript(`
                function() {
                    ${purposeTransferClassName}.reset();
                }
            `);
        });;
    });

    executeScript(`
        function() {
            ${purposeTransferClassName} = function() {};
            let transfer = ${purposeTransferClassName};
            transfer.reset = () => {
                transfer.pendingResolve = null;
                transfer.pendingReject = null;
            };
            transfer.reset();

            if (!navigator.canShare) {
                navigator.canShare = (data) => {
                    if (!data) {
                        return false;
                    }

                    if (data.title === undefined && data.text === undefined && data.url === undefined) {
                        return false;
                    }

                    if (data.url) {
                        // check if URL is valid
                        try {
                            new URL(data.url, document.location.href);
                        } catch (e) {
                            return false;
                        }
                    }

                    return true;
                }
            }

            if (!navigator.share) {
                navigator.share = (data) => {
                    return new Promise((resolve, reject) => {
                        if (!navigator.canShare(data)) {
                            return reject(new TypeError());
                        }

                        if (data.url) {
                            // validity already checked in canShare, hence no catch
                            data.url = new URL(data.url, document.location.href).toString();
                        }

                        if (!window.event || !window.event.isTrusted) {
                            return reject(new DOMException("navigator.share can only be called in response to user interaction", "NotAllowedError"));
                        }

                        if (transfer.pendingResolve || transfer.pendingReject) {
                            return reject(new DOMException("A share is already in progress", "AbortError"));
                        }

                        transfer.pendingResolve = resolve;
                        transfer.pendingReject = reject;

                        const event = new CustomEvent("pbiPurposeMessage", {
                            detail: {
                                action: "share",
                                payload: data
                            }
                        });
                        window.dispatchEvent(event);
                    });
                };
            }
        }
    `);
}
