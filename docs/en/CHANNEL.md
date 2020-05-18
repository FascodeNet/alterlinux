# What is a channel
Channel is an AlterLinux original mechanism that is made so that you can easily switch the files (airootfs) to be included in the image file, the packages to install, the configuration files, etc.  
This mechanism allows you to easily create an AlterOS derivative OS.  
Initially it was only possible to switch packages, but now the specifications have changed significantly and various changes can be made for each channel.  
  
  
The following are channel specifications as of May 13, 2020.  


# Let the script recognize the channel
The conditions for the script to recognize the channel are as follows.

- There is a channel name directory in `channels`
- The directory is not empty

The script will not recognize it if you create an empty directory or create it somewhere else.  
You can check with `./build.sh -h` to see if the script recognized the channel.  
Channels that are not displayed in the Help channel list cannot be used.  


# About channel name
The channel name is basically a directory name in `channels`.  
All the characters that can be used in the directory name can be used in the channel name, but if you use blank characters or double-byte characters, it may not work properly in some environments.  
In addition, it is desirable to keep the channel name within 18 characters because it is handled in the script. (If the number of characters is longer than this, the channel name will not be displayed correctly in the help.)  
  
If the directory name ends in `.add`, the channel name will be the string before` .add`.  
This is to exclude it from Git management and add your own customized channel.  
Finally, run `./build -h` to check the channel name that can be used as an argument.  

## About duplicate channel names
**Please be careful not to duplicate the channel names with and without `.add`!**  
When the one with .add is duplicated with the one without .add, **the one with .add has priority**.  
Please note that channels without `.add` will be unavailable at all.  
Also, the following special channel names cannot be used.  


# Special channel
There are some special channels. These channels are built into the script and cannot be added or removed.

## share
The `share` channel is a shared channel used regardless of the specified channel.  
`share` has the same structure as other channels, but you cannot specify` share` alone as a channel and build it.  
Add here basic packages and common files that will be installed on all channels.  
  
## rebuild
This channel is visible in the help, but it is not a directory entity.This channel is embedded in the script.  
This channel is a channel to read the file which saved the build option generated in the working directory and rebuild.  
This channel is embedded in the script.  

# Specifications of each channel
The main directories that make up a channel are `airootfs` and` packages`.  
The `airootfs` directory installs the package and overwrites` / `just before running` mksquashfs`.  
The `packages` directory contains a text file that describes the list of packages to install.  
There are several other files that can be used in some cases.  


## Directories whose names start with airootfs
Please place the file as `/` in each directory. The permissions of all files are inherited as much as possible.  

### airootfs.any
First overwrite the live environment, regardless of architecture.  

### airootfs.i686 airootfs.x86_64
Airootfs for each architecture.  
`airootfs.x86_64` is used for the` x86_64` architecture, and `airootfs.i686` is used for the` i686`.  

### File duplication priority
For each channel and the file of the `share` channel, the file of each channel has priority.  
Also, in the `airootfs.any` and directories for each architecture, the one for each architecture takes precedence.  
The following shows the order in which the `airootfs` are copied. In summary, the left has the least priority and the right has the priority.  
  
`share/airootfs.any` -> `share/airootfs.<architecture>` -> `<channel_name>/airootfs.any` -> `<channel_name>/airootfs.<architecture>`


## customize_airootfs.sh
If the file `/root/customize_airootfs_ <channel_name>.sh` is placed in the `airootfs` of each channel, the build script will execute the script after `customize_airootfs.sh` is executed.  
（Since `customize_airootfs.sh` is placed by` airootfs.any` of the `share` channel, you can freely overwrite it on each channel.）  
If you want to change the rootfs settings, create this file.  
 

## packagesから始まるディレクトリ
このディレクトリ内に配置された、ファイル名が`.<architecture>`で終わるがパッケージリストとして読み込まれます。  
1行で1つのパッケージとして扱い、`#`から始まる行はコメントとして扱われます。  

パッケージ名やパッケージリストのファイル名に空白文字や全角文字を含めると正常に動作しない可能性があります。


### ディレクトリの種類
各アーキテクチャごとにパッケージリストを入れるディレクトリがあります。`airootfs`と違ってアーキテクチャの共有はありません。
例えば`x86_64`アーキテクチャならば`packages.x86_64`が読み込まれます。


### 特殊なパッケージ
一部、パッケージリストに記述してはいけないパッケージが有ります。  
詳細は[こちら](PACKAGE.md)を参照して下さい。  


### 特殊なパッケージリスト
特殊なパッケージリストとして、`jp.<architecture>`と`non-jp.<architecture>`があります。  
`-j`オプションによって日本語が有効化されている時、スクリプトは`jp.<architecture>`を読み込みます。  
反対に日本語が有効化されていない場合、スクリプトは`non-jp.<architecture>`を使用します。  


### 除外リスト
もしあなたが`share`チャンネルのパッケージでどうしてもインストールしたくないパッケージがある場合、各チャンネルの`packages`ディレクトリ内に`exclude`というファイルを作成し、その中にパッケージを記述することでパッケージを除外することができます。  
例えば`share`で必ずインストールされる`alterlinux-calamares`をインストールしたくない場合、そのチャンネルの`exclude`にパッケージ名を追加することでインストールされなくなります。  
（その場合は各チャンネルのcustomize_airootfsで不要なファイルを削除して下さい。）  
パッケージの記述方法はパッケージリストと同様で、1行で1つのパッケージとして扱い、`#`から始まる行はコメントとして扱われます。  
  
除外できないパッケージも存在します。  
スクリプトによって強制的にインストールされるパッケージ（`efitools`など）は除外リストに関係なくインストールされます。  
例えば`exclude`に`plymouth`を記述しても`-b`オプションが有効化された場合は強制的にインストールされます。  
Plymouthを強制的に無効化したい場合は`exclude`ではなく各チャンネルの`config`より`boot_splash`を`false`に固定して下さい。  
  
`channels/share/packages/exclude`は、スクリプトによって強制的にインストールされるパッケージの一覧が記述されています。  
これは作業ディレクトリに正確にログを記録し、チャンネルによって使用不可能なパッケージがインストールされるのを防ぐためです。  
  
また、`exclude`はパッケージを削除するわけではないため依存関係によってインストールされるパッケージを除外することはできません。  


### excludeの適用されるタイミング
`exclude`はパッケージが全て読み込まれた後に適用されます。  
  
パッケージが読み込まれる順番は以下のとおりです、
`share/packages.<architecture>` -> `<channel_name>/packages.<architecture>`  
  
その後に以下の順番でexcludeが読み込まれ、パッケージが除外されます。  
`share/packages.<architecture>/exclude` -> `<channel_name>/packages.<architecture>`


## description.txt
これはチャンネルの説明を記述したテキストファイルです。`channels/<channel_name>/description.txt`に配置されます。  
このファイルは必須ではありません。このファイルが無い場合、ヘルプには`This channel does not have a description.txt.`と表示されます。  

このファイルは1行で記述することが推奨されています。複数行を記述する必要がある場合、テキストのレイアウトを考えて2行目以降は先頭に19個の半角空白文字を入れたほうが良いでしょう。  
  

## pacman.conf
`channels/<channel_name>/pacman-<architecture>.conf`を配置すると、ビルド時にそのファイルを使用します。ただし、インストール後の設定ファイルは置き換えないので`airootfs`で`/etc/pacman.conf`を配置して下さい。


## splash.png
`channels/<channel_name>/splash.png`を配置すると、SYSLINUXのブートローダの背景を変更することができます。  
PNG形式の画像で640x480の画像を配置してください。


## config
既存のビルド設定を上書きするスクリプトです。かならずシェルスクリプトの構文で記述して下さい。  
雛形が`build.sh`と同じ階層に設置してあります。  
この設定ファイルは**引数による設定さえ**上書きしてしまうため、最小限の必須項目のみを記述するようしてください。（例えばPlymouthのテーマ名やパッケージ名など）  
  
## 警告
スクリプト内ではローカル変数の定義以外を絶対に行わないで下さい。グローバル変数の定義やその他のコマンドの実効は思わぬ動作につながる危険性が有ります。

### アーキテクチャごとの設定と優先順位
`channels/<channel_name>/config.any`が読み込まれた後`channels/<channel_name>/config.<architecture>`が読み込まれます。


## architecture
そのチャンネルで利用可能なアーキテクチャの一覧です。`#`はコメントとして扱われます。