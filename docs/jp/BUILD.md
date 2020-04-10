## AlterLinuxをビルドする

以下の手順は、実機のArchLinuxでビルドするためのものです。

### 準備

ビルドは実機のArch Linuxを利用する方法とDocker上でビルドする方法があります。
`build.sh`のオプションは共通です。

```bash
git clone https://github.com/SereneTeam/alterlinux.git alterlinux
cd ./alterlinux/
```
AlterLinuxには鍵を簡単に追加するスクリプトが含まれています。

```bash
sudo ./keyring.sh --alter-add
```

### 実機でビルドする
実機でビルドする場合はArchLinux環境でビルドする必要があります。　　
ソースコードをダウンロードしてください。

```bash
git clone https://github.com/SereneTeam/alterlinux.git
cd alterlinux
```

#### ビルドウィザード
実機で直接ビルドする場合、wizard.shを使用して簡単に思い通りの設定でビルドできます。bashで書かれていますのでターミナルから実行してください。
「はい」か「いいえ」の質問は`y`か`n`で応えてください。数値を入力する場合は半角で入力してください。

```bash
./wizard.sh
```

#### 手動でオプションを指定してビルドする
ビルドに必要なパッケージをインストールして下さい。  

```bash
sudo pacman -S --needed git make arch-install-scripts squashfs-tools libisoburn dosfstools lynx archiso
```
オプションは[こちら](#buildsh-options)を参照して下さい。

### コンテナ上でビルドする
Dockerでビルドする場合は、[この手順](jp/DOCKER.md)を参照してください。

### build.shのオプション

#### 基本
通常はウィザードを使用してください。
デフォルトパスワードは`alter`です。
lymouthは無効化されています。
デフォルトの圧縮方式は`zstd`です。

```bash
./build.sh <options> <channel>
```

#### オプション
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
2020年3月21日現在でサポートされているチャンネルは以下のとおりです。
名前 | 目的
--- | ---
xfce | デスクトップ環境にXfce4を使用し、様々なソフトウェアを追加したデフォルトのチャンネルです。
plasma | PlasmaとQtアプリを搭載したエディションです。 現在開発中で、安定していません。


#### カーネルについて
カーネルは現在、以下の種類がサポートされています。未指定の場合は通常の`linux`カーネルが使用されます。
`-k`のオプションは必ず`linux-foo`の`foo`の部分を入れてください。例えば`linux-lts`の場合は`lts`が入ります。

以下はサポートされている値とカーネルです。カーネルの説明は[ArchWiki](https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB)を引用しています。

名前 | 特徴
--- | ---
ck | linux-ck にはシステムのレスポンスを良くするためのパッチが含まれています。
lts | coreリポジトリにある長期サポート版 (Long term support, LTS) の Linux カーネルとモジュール。
lqx | デスクトップ・マルチメディア・ゲーム用途に Debian 用の設定と ZEN カーネルソースを使ってビルドされたディストロカーネル代替
rt | このパッチを使うことでカーネルのほとんど全てをリアルタイム実行できるようになります。
zen | linux-zenはカーネルハッカーたちの知恵の結晶です。日常的な利用にうってつけの最高の Linux カーネルになります。

##### 圧縮方式について
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