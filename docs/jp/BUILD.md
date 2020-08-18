## Alter Linuxをビルドする
ビルドは実機のArch Linuxを利用する方法とDocker上でビルドする方法があります。  
Dockerでビルドする方法は[この手順](jp/DOCKER.md)を参照してください。  
  
実機でビルドする場合は、必ずOSがArchLinuxかAlter Linuxでなければなりません。  
以下では実機でビルドする方法を解説します。  
  
ArchやAlter上で直接ビルドする場合、ビルドはいくつかの方法で行うことができます。

### 準備

ソースコードを取得します。  

```bash
git clone https://github.com/FascodeNet/alterlinux.git
cd alterlinux
```

Alter Linuxのリポジトリを利用するための鍵を追加します。  

```bash
sudo ./keyring.sh --alter-add --arch32-add
```

ビルドに必要なパッケージをインストールします。

```bash
sudo pacman -S --needed git make arch-install-scripts squashfs-tools libisoburn dosfstools lynx archiso
```

### TUIを使用する
`menuconfig`を使用して設定を行いビルドできます。  

```bash
make menuconfig
```

### GUIを使用する
GUIで設定を行ってビルドできます。

```bash
python ./build-wizard.py
```

### ビルドウィザードを使用する
実機で直接ビルドする場合、wizard.shを使用して簡単に思い通りの設定でビルドできます。  
下記の鍵の追加や依存関係のインストールなどを全て自動で行います。  
bashで書かれていますのでターミナルから実行してください。  
「はい」か「いいえ」の質問は`y`か`n`で応えてください。数値を入力する場合は半角で入力してください。  
ウィザードの使い方の詳細は[公式ブログ](https://blog.fascode.net/2020/04/17/build-alterlinux/)で紹介しています。  

```bash
./wizard.sh
```

### 手動でオプションを指定してビルドする

`build.sh`を実行して下さい。  

```bash
sudo ./build.sh [options] [channel]
```

### build.shの使い方

主なオプションは以下のとおです。完全なオプションと使い方は`./build -h`を実行して下さい。  

用途 | 使い方
--- | ---
ブートスプラッシュを有効化 | -b
カーネルを変える | -k [kernel]
ユーザ名を変える | -u [username]
パスワードを変更する | -p [password]
日本語にする | -j
圧縮方式を変更する | -c [comp type]
圧縮のオプションを設定する | -t [comp option]
出力先ディレクトリを指定する| -o [dir]
作業ディレクトリを指定する | -w [dir]

##### 注意
チャンネル名以降に記述されたオプションは全て無視されます。必ずチャンネル名の前にオプションを入れて下さい。

#### 例
以下の条件でビルドするにはこのようにします。

- Plymouthを有効化
- 圧縮方式は`gzip`
- カーネルは`linux-lqx`
- パスワードは`ilovearch`

```bash
./build.sh -b -c "gzip" -k "lqx" -p 'ilovearch' xfce
```


### 注意事項
#### チャンネルについて
チャンネルは、インストールするパッケージと含めるファイルを切り替えます。  
この仕組みにより様々なバージョンのAlter Linuxをビルドすることが可能になります。  
2020年5月5日現在でサポートされているチャンネルは以下のとおりです。  
完全なチャンネルの一覧は`./build.sh -h`を参照して下さい。  

名前 | 目的
--- | ---
basic | 様々なチャンネルの基礎となるGUIの無いチャンネル
cinnamon | 多くのアプリケーションを備えた豪華なシナモンデスクトップのチャンネル
gnome | カスタマイズされたGnomeデスクトップ環境のチャンネル
i3 | カスタマイズされたi3wmと最小限のソフトが入ったチャンネル
lxde | LXDEと最小限のアプリケーションのみが入っているrelengを除いて最も軽量なチャンネル
plasma | PlasmaとQtアプリを搭載した現在開発中のチャンネル
releng | 純粋なArchLinuxのライブ起動ディスクをビルドできるチャンネル
rebuild | 作業ディレクトリにある設定を利用して再ビルドを行う特殊なチャンネル
xfce | デスクトップ環境にXfce4を使用し、様々なソフトウェアを追加したデフォルトのチャンネル
xfce-pro | xfceチャンネルのウィンドウマネージャを変更祭し、多くのソフトを追加したチャンネル


#### カーネルについて
`i686`アーキテクチャと`x86_64`アーキテクチャでは共にArchLinuxの公式カーネルである`linux`や`linux-lts`、`linux-zen`をサポートしています。  
また`x86_64`では公式カーネルに加えて以下のカーネルをサポートしています。
カーネルの説明は[ArchWiki](https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB)を引用しています。

名前 | 特徴
--- | ---
ck | linux-ck にはシステムのレスポンスを良くするためのパッチが含まれています。
lts | coreリポジトリにある長期サポート版 (Long term support, LTS) の Linux カーネルとモジュール。
lqx | デスクトップ・マルチメディア・ゲーム用途に Debian 用の設定と ZEN カーネルソースを使ってビルドされたディストロカーネル代替
rt | このパッチを使うことでカーネルのほとんど全てをリアルタイム実行できるようになります。
zen-letsnote | Let's Noteでサスペンドの問題が発生しないようにパッチを当てた`linux-zen`カーネル（Alter Linux独自）

##### 注意
`-k`のオプションは必ず`linux-foo`の`foo`の部分のみを入れてください。例えば`linux-lts`の場合は`lts`が入ります。


#### 圧縮方式について
圧縮方式と詳細のオプションは`mksquashfs`のヘルプを参照してください。
2019年2月12日現在で、`mksquashfs`が対応している方式とオプションは以下の通りです。

```
gzip
    -Xcompression-level <compression-level>
    <compression-level> should be 1 .. 9 (default 9)
    -Xwindow-size <window-size>
    <window-size> should be 8 .. 15 (default 15)
    -Xstrategy strategy1,strategy2,...,strategyN
    Compress using strategy1,strategy2,...,strategyN in turn
    and choose the best compression.
    Available strategies: default, filtered, huffman_only,
    run_length_encoded and fixed
lzma (no options)
lzo
    -Xalgorithm <algorithm>
    Where <algorithm> is one of:
        lzo1x_1
        lzo1x_1_11
        lzo1x_1_12
        lzo1x_1_15
        lzo1x_999 (default)
    -Xcompression-level <compression-level>
    <compression-level> should be 1 .. 9 (default 8)
    Only applies to lzo1x_999 algorithm
lz4
    -Xhc
    Compress using LZ4 High Compression
xz
    -Xbcj filter1,filter2,...,filterN
    Compress using filter1,filter2,...,filterN in turn
    (in addition to no filter), and choose the best compression.
    Available filters: x86, arm, armthumb, powerpc, sparc, ia64
    -Xdict-size <dict-size>
    Use <dict-size> as the XZ dictionary size.  The dictionary size
    can be specified as a percentage of the block size, or as an
    absolute value.  The dictionary size must be less than or equal
    to the block size and 8192 bytes or larger.  It must also be
    storable in the xz header as either 2^n or as 2^n+2^(n+1).
    Example dict-sizes are 75%, 50%, 37.5%, 25%, or 32K, 16K, 8K
    etc.
zstd
    -Xcompression-level <compression-level>
    <compression-level> should be 1 .. 22 (default 15)
```