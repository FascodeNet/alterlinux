## Build AlterLinux
There are two ways to build, one is to use the actual Arch Linux and the other is to build on Docker.  
Please refer to [This procedure] (DOCKER.md) for how to build with Docker.  
  
When building on a real machine, the OS must be ArchLinux or AlterLinux.
The following explains how to build on a real machine.  
  
The build can be done in two ways. You can either use the wizard or run it directly.  

### Get the source code

```bash
git clone https://github.com/SereneTeam/alterlinux.git
cd alterlinux
```

### Use the build wizard
When you build directly on the actual machine, you can easily build with your desired settings using wizard.sh.  
The following keys are added and dependencies are automatically installed.  
It is written in bash, so please execute it from the terminal.  
Answer "yes" or "no" questions with `y` or` n`. If you enter a numerical value, enter it in half-width characters.  

```bash
./wizard.sh
```

### 手動でオプションを指定してビルドする

#### 鍵を追加する
AlterLinuxには鍵を簡単に追加するスクリプトが含まれています。

```bash
sudo ./keyring.sh --alter-add --arch32-add
```

#### 依存関係をインストールする
ビルドに必要なパッケージをインストールして下さい。  

```bash
sudo pacman -S --needed git make arch-install-scripts squashfs-tools libisoburn dosfstools lynx archiso
```

#### ビルドを開始する
`build.sh`を実行して下さい。  

```bash
sudo ./build.sh
```

`build.sh`の使い方は以下をご覧ください。

### build.sh

#### 基本

```bash
./build.sh <options> <channel>
```

##### 注意
チャンネル名以降に記述されたオプションは全て無視されます。必ずチャンネル名の前にオプションを入れて下さい。

#### オプション
完全なオプションと使い方は`./build -h`を実行して下さい。

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


#### 例
以下の条件でビルドするにはこのようにします。

- Plymouthを有効化
- 圧縮方式は`gzip`
- カーネルは`linux-lqx`
- パスワードは`ilovearch`

```bash
./build.sh -b -c "gzip" -k "lqx" -p 'ilovearch' xfce
```


#### チャンネルについて
チャンネルは、インストールするパッケージと含めるファイルを切り替えます。
この仕組みにより様々なバージョンのAlterLinuxをビルドすることが可能になります。
2020年5月5日現在でサポートされているチャンネルは以下のとおりです。

名前 | 目的
--- | ---
xfce | デスクトップ環境にXfce4を使用し、様々なソフトウェアを追加したデフォルトのチャンネルです。
plasma | PlasmaとQtアプリを搭載したエディションです。 現在開発中で、安定していません。
lxde | LXDEと最小限のアプリケーションのみが入っています。(relengを除き)最も軽量です。
releng | 純粋なArchLinuxのライブ起動ディスクをビルドすることができます。
rebuild | 作業ディレクトリにある設定を利用して再ビルドを行います。


#### カーネルについて
`i686`アーキテクチャと`x86_64`アーキテクチャでは共にArchLinuxの公式カーネルである`linux`や`linux-lts`、`linux-zen`をサポートしています。  
また`x86_64`では公式カーネルに加えて以下のカーネルをサポートしています。
カーネルの説明は[ArchWiki](https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB)を引用しています。

Name | Characteristic
--- | ---
ck | linux-ck contains patches to improve system responsiveness
lts | Long term support (LTS) Linux kernel and modules in the core repository
lqx | Distro kernel replacement built with Debian settings and ZEN kernel source for desktop multimedia games
rt | This patch will allow you to run almost all of your kernel in real time
zen-letsnote | A `linux-zen` kernel patched to prevent suspend issues with Let's Note (AlterLinux specific)

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