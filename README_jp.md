
## AlterLinux - 誰でも使えることを目標にした日本製のArchLinux派生のOS

![License](https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=appveyor)
![Base](https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=appveyor)
![archiso](https://img.shields.io/badge/archiso--version-43--1-blue?style=for-the-badge&logo=appveyor)

## 概要
  
Alter LinuxはArch Linuxをベースに開発されている新しいOSです。  
Xfce4による洗練されたUIとGUIで完結するパッケージ管理ツールを兼ね備え、誰でも簡単に拘束で最新のOSを使用できます。  
  
You can find the English version of this Readme [here](https://github.com/SereneTeam/alterlinux/blob/master/README.md).  


## リポジトリとソフトウェア

### リポジトリ
- [SereneTeam/alter-repo](https://github.com/SereneTeam/alter-repo)  
全てのミラーサーバはこのリポジトリと同期しています。  


### ソフトウェア
Alter Linuxに入っている独自のソフトウェアのソースコードは以下にあります。
全てのパッケージ一覧は[こちら](https://github.com/SereneTeam/alterlinux/blob/master/packages.x86_64)にあります。

- [EG-Installer](https://github.com/Hayao0819/EG-Installer)([PKGBUILD](https://github.com/Hayao0819/EG-Installer-PKGBUILD))
- [plymouth-theme-alter](https://github.com/yamad-linuxer/plymouth-theme-alter)([PKGBUILD](https://github.com/Hayao0819/plymouth-theme-alter))

AURに無いソフトウェアのソースコードは以下にあります。

- [calamares](https://gitlab.manjaro.org/applications/calamares)([PKGBUILD](https://gitlab.manjaro.org/packages/extra/calamares))


## ビルド

以下の手順は、実機のArchLinuxでビルドするためのものです。

### 準備

ビルドは実機のArch Linuxを利用する方法とDocker上でビルドする方法があります。  
`build.sh`のオプションは共通です。  

#### 実機でビルドする
ArchLinux環境でビルドする必要があります。  
事前に`archiso`パッケージをインストールしておいてください。

```bash
git clone https://github.com/SereneTeam/alterlinux.git
cd alterlinux
./build.sh <options>
```

#### コンテナ上でビルドする
Dockerでビルドする場合は、[この手順](https://github.com/SereneTeam/alterlinux/blob/master/Howtobuild_on_docker.md)を参照してください。

### build.shのオプション

#### 基本
そのまま実行してください。  
デフォルトパスワードは`alter`です。  
Plymouthは無効化されています。  
デフォルトの圧縮方式は`xz`です。

#### オプション
- Plymouthを有効化する ：   `-b`
- パスワードを変更する   ：   `-p <password>`
- 圧縮方式を変える      ：   `-c <comp type>`
- 圧縮のオプション      ：   `-t <options>`

例 ： Plymouthを有効化し、パスワードを`ilovearch`に変更し、圧縮方式を`zstd`にする。

```bash
./build.sh -b -p 'ilovearch' -c "zstd"
```

##### 圧縮方式について
圧縮方式と詳細のオプションは`mksquashfs`のヘルプを参照してください。
2019年2月12日現在で、`mksquashfs`が対応している方式とオプションは以下の通りです。

```
gzip (default)
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


## SereneTeamと開発者について
SereneTeamは主に中高生で構成されたLinuxディストリビューションの開発チームです。ほぼ全員が日本人で、メンバーは合計で24人います。  
Ubuntuをベースとした[SereneLinux](serenelinux.com)を開発、公開しています。  
私達はそのノウハウを活かし、日本での開発は初めてとなるArch Linux派生のOSとなるAlter Linuxの開発に取り組んでいます。  

### メンバーのTwitter
主要な開発メンバーのTwitterへのリンクです。

#### 開発担当
- [Hayao0819](https://twitter.com/Hayao0819)
- [lap1sid](https://twitter.com/Pixel_3a)
- [yamad](https://twitter.com/_unix_like)

#### デザイン担当
- [tukutun](https://twitter.com/tukutuN_27)