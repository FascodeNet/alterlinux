var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [
            ],
            "config": {
                "/": {
                    "ItemGeometriesHorizontal": "",
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/Configuration": {
                    "PreloadWeight": "34"
                },
                "/General": {
                    "ToolBoxButtonState": "topcenter",
                    "ToolBoxButtonX": "744"
                },
                "/Wallpaper/org.kde.image/General": {
                    "Image": "file:///usr/share/backgrounds/alter.png"
                }
            },
            "wallpaperPlugin": "org.kde.image"
        }
    ],
    "panels": [
        {
            "alignment": "left",
            "applets": [
                {
                    "config": {
                        "/": {
                            "PreloadWeight": "100"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "540",
                            "DialogWidth": "720"
                        },
                        "/General": {
                            "favoritesPortedToKAstats": "true",
                            "icon": "/usr/share/icons/hicolor/scalable/alter.svg"
                        },
                        "/Shortcuts": {
                            "global": "Alt+F1"
                        }
                    },
                    "plugin": "org.kde.plasma.kickoff"
                },
                {
                    "config": {
                        "/": {
                            "PreloadWeight": "34"
                        }
                    },
                    "plugin": "org.kde.plasma.pager"
                },
                {
                    "config": {
                        "/": {
                            "PreloadWeight": "34"
                        }
                    },
                    "plugin": "org.kde.plasma.systemtray"
                },
                {
                    "config": {
                        "/": {
                            "PreloadWeight": "34"
                        }
                    },
                    "plugin": "org.kde.plasma.digitalclock"
                },
                {
                    "config": {
                        "/": {
                            "PreloadWeight": "34"
                        }
                    },
                    "plugin": "org.kde.plasma.showdesktop"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.icontasks"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/ConfigDialog": {
                    "DialogHeight": "72",
                    "DialogWidth": "1920"
                },
                "/Configuration": {
                    "PreloadWeight": "34"
                }
            },
            "height": 2,
            "hiding": "normal",
            "location": "bottom",
            "maximumLength": 106.66666666666667,
            "minimumLength": 106.66666666666667,
            "offset": 0
        }
    ],
    "serializationFormatVersion": "1"
}
;

plasma.loadSerializedLayout(layout);
