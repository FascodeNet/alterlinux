# Thank you for try Alter Linux i3 Edition
This document will show how to use Alter Linux i3 Edition.  
このドキュメントでは、Alter Linux i3エディションの使い方を紹介します。

1. 日本語
1. English

---
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
| ショートカット | 内容                                  |
| -------------- | ------------------------------------- |
| mod+Shift+S    | テーママネージャ (パネルの見た目変更) |
| mod+B          | システム設定マネージャ                |


この他にも多数の便利なショートカットがあります。


## 設定を変更したい
カスタマイズを加えたい場合は、この項目を参考にしてください。
- パネルを変えたい  
後述のテーママネージャを使用してください
- 画面の解像度など、システムの設定を変更したい  
後述のbmenu (設定マネージャ) を使用してください
- 壁紙を変えたい  
`~/.config/i3/config` を編集し、16行目 `exec --no-startup-id "feh --bg-fill ***` の***の位置に、壁紙のパスを記述してください
- 操作方法が表示されたウィンドウを非表示にしたい  
`~/.config/conky` を削除する、もしくは `~/.config/i3/config` を編集し、42行目 (`exec --no-startup-id conky`) を削除することで無効に出来ます


## テーママネージャについて
mod+Shift+S で、Alter Linux i3独自のテーママネージャを起動できます。  
このテーママネージャでは、画面の上 (デフォルト) にあるパネルの見た目、位置などを変更することが出来ます。

## bmenu (システム設定マネージャ) について
mod+Bで、システム設定マネージャを起動できます。  
このショートカットを押すと、新規ターミナル上でbmenuが起動します。変更したい設定に該当するカテゴリの数字を入力し、設定を変更してください。


## Q&A
- わからないことがある  
Twitter [(@Fascode_SPT)](https://twitter.com/Fascode_SPT) へのDMや返信等で気軽に聞いてください。

---

## Shortcut keys
i3wm has many useful shortcut keys. Most of the shortcuts are in combination with a key called [mod].  
Here are some of them.

### Key Definitions
- mod : super (Windows key)
- Arrow : ←[ j ], ↓[ k ], ↑[ l ], →[ ; ] key (you can substitute the key in parentheses)

### Most important shortcut
| Shortcuts      | Contents            |
| -------------- | ------------------- |
| mod+Enter      | Open a new terminal |
| mod+Shift+Q    | Kill active window  |
| mod+D          | Software launcher   |
| super+Esc      | Screen lock         |
| mod+Shift+E    | Power menu          |
|                | (on the power menu) |
|  S             | Shutdown            |
|  R             | Reboot              |
|  O             | logOut              |
|  L             | Lock                |
|  Q, Esc, Enter | Canncel             |

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


## I want to change settings
If you want to add some customization, please refer to this section.
- Change the panel  
Use the Theme Manager described below
- Change the system settings, such as screen resolution, etc.  
Use bmenu (setting manager) as described below
- Change the wallpaper.  
Edit `~/.config/i3/config` , and add line 16 `exec --no- startup-id "feh --bg-fill ***` with the path to the wallpaper in the *** position.
- Hide the window with the operating instructions.  
Remove `~/.config/conky` , or edit `~/.config/i3/config` and remove line 42 (`exec --no-startup-id conky `)


## About the Theme Manager
You can use mod+Shift+S to launch Alter Linux i3's own theme manager.  
The theme manager allows you to change the appearance, position, etc. of the panel at the top of the screen (by default).  
This theme manager allows you to change the appearance, position, etc. of the panels at the top of the screen (the default) You can do.

## About bmenu (System setting manager)
You can use mod+B to start the System Configuration Manager.  
Pressing this shortcut will launch bmenu in a new terminal. Enter the number of the category that corresponds to the setting you want to change.


## Q&A
- There's something I don't understand  
Feel free to ask by DM or reply to Twitter [(@Fascode_SPT)](https://twitter.com/Fascode_SPT).


---

		Alter Linux i3 edition help document
		Watasuke
		Twitter: @Watasuke102
		Email  : Watasuke102@gmail.com
		(c) 2020 Fascode Network.