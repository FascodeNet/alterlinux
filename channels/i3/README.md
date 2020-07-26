# Thank you for try Alter Linux i3 Edition
This document will show how to use Alter Linux i3 Edition.  
このドキュメントでは、Alter Linux i3エディションの使い方を紹介します。

1. [日本語](#目次)
1. [English](#Table-of-Contents)

---
## 目次
1. [基本的な使い方](#基本的な使い方)
	1. [ソフトを起動する](#ソフトを起動する)
	1. [ウィンドウの簡易的な操作](#ウィンドウの簡易的な操作)
	1. [ソフトを追加・更新する](#ソフトを追加・更新する)
	1. [シャットダウンする](#シャットダウンする)
	1. [テーマを変更する](#テーマを変更する)
	1. [システム設定マネージャを使用する](#システム設定マネージャを使用する)
	1. [インストール方法](#インストール方法)
1. [ショートカットキー](#ショートカットキー)
	1. [キーの定義](#キーの定義)
	1. [重要ショートカット](#重要ショートカット)
	1. [ワークスペース・ウィンドウ](#ワークスペース・ウィンドウ)
	1. [ソフトウェア](#ソフトウェア)
1. [設定を変更したい](#設定を変更したい)
1. [その他](#その他)

## 基本的な使い方{#1}
i3wmはタイル型ウィンドウマネージャです。ウィンドウが増えるたびに、i3wmは自動でウィンドウをリサイズし、整列させます。  
基本的な操作はショートカットで行います。ショートカットについては、[こちら](#ショートカットキー)を参考にしてください。  
豊富なショートカットが用意されていますが、その全てを覚える必要はありません。まずはデスクトップに表示しているショートカットキーを覚えるところからはじめましょう。

### ソフトを起動する
ソフトを起動するために、ランチャーが用意されています。  
mod(Windowsキー)+Dでランチャーを起動し、上下キーでソフトを選択、Enterキーで起動します。  
デフォルトでインストールされている主なソフトの一部を紹介します。
- Chromium (Webブラウザー)
- Thunderbird (メーラー)
- VLC メディアプレイヤー
- LibreOffice
### ウィンドウの簡易的な操作
mod+上下左右キーで、アクティブなウィンドウを切り替えることが出来ます。  
また、mod+Shift+Qキーで、アクティブなウィンドウを閉じることが出来ます。
### ソフトを追加・更新する
mod+Dキーでランチャーを開き、「ソフトウェアの追加と削除」を起動してください。ストアが表示されます。  
ソフトの更新は、上部の「アップデート」タブからすることができます。  
「パッケージが見つかりません」と表示された場合は、右上のメニューから「データベースをアップデートする」を選択してください。
### シャットダウンする
mod(Windows)+Shift+iキーでメニューが表示されます。  
「Shutdown」を選択することでシャットダウンが開始されます。  
また、再起動やスリープなどもここから選択することが出来ます。
## テーマを変更する
mod+Shift+S で、Alter Linux i3独自のテーママネージャを起動できます。  
このテーママネージャでは、画面の上 (デフォルト) にあるパネルの見た目、位置などを変更することが出来ます。
## システム設定マネージャを使用する
mod+Bで、システム設定マネージャを起動できます。  
このショートカットを押すと、新規ターミナル上で設定マネージャが起動します。変更したい設定に該当するカテゴリの数字を入力し、設定を変更してください。
### インストール方法
ライブ環境を試してみて、インストールしてみたいと思ったら、mod+iキーでインストーラが起動します。  
インストーラの指示通りに進み、インストールしてみてください。


## ショートカットキー
i3wmには多数の便利なショートカットがあります。ショートカットは[mod]と呼ばれるキーとの組み合わせであることがほとんどです。  
ここでは、ショートカットの一部を紹介します。

### キーの定義
- mod : super (Windowsキー)
- Arrow : ←[ j ], ↓[ k ], ↑[ l ], →[ ; ]キー (カッコ内キーで代用可)


### 重要ショートカット
| ショートカット | 内容                         |
| -------------- | ---------------------------- |
| mod+Enter      | ターミナルを開く             |
| mod+Shift+Q    | アクティブウィンドウを閉じる |
| mod+D          | ランチャーの表示             |
| super+Esc      | 画面のロック                 |
| mod+Shift+E    | 電源メニュー                 |
|                | (電源メニュー時)             |
|  S             | シャットダウン               |
|  R             | 再起動                       |
|  O             | ログアウト                   |
|  L             | ロック                       |
|  Q, Esc, Enter | キャンセル                   |

### ワークスペース・ウィンドウ
| ショートカット  | 内容                                                |
| --------------- | --------------------------------------------------- |
| mod+0-9         | ワークスペースの変更                                |
| mod+R           | リサイズモード (リサイズモード中に押すとキャンセル) |
| mod+Shift+0-9   | アクティブウィンドウを他のワークスペースに移動する  |
| mod+Arrow       | アクティブウィンドウの切り替え                      |
| mod+Shift+Arrow | アクティブウィンドウの移動                          |
| mod+h           | 新規ウィンドウの作成位置を水平 (横) 方向にする      |
| mod+v           | 新規ウィンドウの作成位置を垂直 (縦) 方向にする      |
| mod+Shift+R     | i3wmの再読込                                        |

### ソフトウェア
| ショートカット   | 内容                                  |
| ---------------- | ------------------------------------- |
| mod+Shift+S      | テーママネージャ (パネルの見た目変更) |
| mod+B            | システム設定マネージャ                |
| mod+Shift+PrtScr | スクリーンショットの撮影              |


この他にも多数の便利なショートカットがあります。


## 設定を変更したい
カスタマイズを加えたい場合は、この項目を参考にしてください。
- パネルを変えたい  
前述のテーママネージャを使用してください
- 画面の解像度など、システムの設定を変更したい  
前述の設定マネージャを使用してください
- 壁紙を変えたい  
`~/.config/i3/config` を編集し、16行目 `exec --no-startup-id "feh --bg-fill ***` の***の位置に、壁紙のパスを記述してください
- 操作方法が表示されたウィンドウを非表示にしたい  
`~/.config/conky` を削除する、もしくは `~/.config/i3/config` を編集し、42行目 (`exec --no-startup-id conky`) を削除することで無効に出来ます




## その他
- わからないことがある  
Twitter [(@Fascode_SPT)](https://twitter.com/Fascode_SPT) へのDMや返信等で気軽に聞いてください。

---

## Table of Contents
1. [Basic Usage](#basic-usage)
	1. [Launch the software](#launch-the-software)
	1. [Simple manipulation of windows](#simple-manipulation-of-windows)
	1. [Add or update software](#add-or-update-software)
	1. [Shutdown](#shutdown)
	1. [Change the theme](#change-the-theme)
	1. [Using the System Configuration Manager](#using-the-System-Configuration-Manager)
	1. [How to install](#how-to-install)
1. [Shortcut keys](#shortcut-keys)
	1. [key definitions](#key-definitions)
	1. [Most important shortcut](#most-important-shortcut)
	1. [Workspace, window](#workspace-window)
	1. [Softwares](#softwares)
1. [How to change the settings](#how-to-change-the-settings)
1. [Q&A](#qa)

## Basic Usage
i3wm is a tiling window manager. Each time you add more windows, i3wm will automatically resize and align them.  
The basic operations are done using shortcuts. See [Shortcut keys](#Shortcut-keys) for more information on shortcuts.  
There are many shortcuts available, but you don't need to remember them all. Let's start by learning the shortcut keys that displaying on your desktop.

### Launch the software
The launcher is installed to launch the software.  
Start the launcher by pressing mod(Windows key)+D, select the software by pressing the up and down keys, and start it by pressing Enter.  
Some of the main software installed by default are listed below.
- Chromium (web browser)
- Thunderbird (mailer)
- VLC Media Player
- LibreOffice
### Simple manipulation of windows
You can use the mod+up, down, left, and right keys to switch between the active windows.  
You can also use the mod+Shift+Q keys to close the active window.
### Add or update software
Use the mod+D keys to open the launcher and launch "Add/Remove Software". The Store will start.  
You can update the software from the 'Update' tab at the top.  
If you get a message "Package not found", select "Update database" from the top right menu.
### Shutdown
Press mod(Windows)+Shift+E to bring up the menu.  
Selecting "Shutdown" will start the shutdown.  
You can also choose "reboot", "Logout" and more.
## Change the theme
You can use mod+Shift+S to launch Alter Linux i3's own theme manager.  
This theme manager allows you to change the appearance, position, etc. of the panels at the top of the screen (the default).
## Using the System Configuration Manager
You can use mod+B to start the System Configuration Manager.  
Pressing this shortcut will launch system manager in a new terminal. Enter the number of the category whose settings you want to change and change the settings.
### How to install
If you want to try the live environment and install it, use the mod+i key to launch the installer.  
Follow the installer's instructions and try to install it.


## Shortcut keys
i3wm has many useful shortcut keys. Most of the shortcuts are in combination with a key called [mod].  
Here are some of them.

### Key Definitions
- mod : super (Windows key)
- Arrow : ←[ j ], ↓[ k ], ↑[ l ], →[ ; ] key (you can substitute the key in parentheses)

### Most important shortcut
| Shortcuts      | Contents               |
| -------------- | ---------------------- |
| mod+Enter      | Open a new terminal    |
| mod+Shift+Q    | Kill active window     |
| mod+D          | Software launcher      |
| super+Esc      | Screen lock            |
| mod+Shift+E    | Power menu             |
| Esc            | Canncel the power menu |

### Workspace, window
| Shortcuts       | Contents                                     |
| --------------- | -------------------------------------------- |
| mod+0-9         | Switch workspaces                            |
| mod+R           | Resize mode (Canncel when )                  |
| mod+Shift+0-9   | Move active window to other workspace        |
| mod+Arrow       | Switch active window                         |
| mod+Shift+Arrow | Move active window                           |
| mod+h           | Change the new window position horizontally  |
| mod+v           | Change the new window position horizontally  |
| mod+Shift+R     | Reload i3wm                                  |

### Softwares
| Shortcuts      | Contents                                      |
| -------------- | --------------------------------------------- |
| mod+Shift+S    | Theme Manager (change the look of the panel ) |
| mod+B          | System setting manager                        |


There are many other useful shortcuts.


## How to change settings
If you want to add some customization, please refer to this section.
- Change the panel  
Use the Theme Manager described above
- Change the system settings, such as screen resolution, etc.  
Use system manager as described above
- Change the wallpaper.  
Edit `~/.config/i3/config` , and add line 16 `exec --no- startup-id "feh --bg-fill ***` with the path to the wallpaper in the *** position.
- Hide the window with the operating instructions.  
Remove `~/.config/conky` , or edit `~/.config/i3/config` and remove line 42 (`exec --no-startup-id conky `)


## Q&A
- There's something I don't understand  
Feel free to ask by DM or reply to Twitter [(@Fascode_SPT)](https://twitter.com/Fascode_SPT).


---

		Alter Linux i3 edition help document
		Watasuke
		Twitter: @Watasuke102
		Email  : Watasuke102@gmail.com
		(c) 2020 Fascode Network.