
## Alter Linux - 誰でも使えることを目標にした日本製でArch Linux派生のOS

![AlterLogo](../images/logo.png)

[![License](https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=gnu)](LICENSE)
[![Base](https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=arch-linux)](https://www.archlinux.org/)
[![archiso](https://img.shields.io/badge/archiso--version-43--1-blue?style=for-the-badge&logo=appveyor)](https://git.archlinux.org/archiso.git/tag/?h=v43)

| [日本語](README_jp.md) | [English](../README.md) |
|:-----:|:-----:|

## 概要
  
Alter LinuxはArch Linuxをベースに開発されている新しいOSです。  
Xfce4による洗練されたUIとGUIで完結するパッケージ管理ツールを兼ね備え、誰でも簡単に高速で最新のOSを使用できます。  
AlterLinuxの最新の状況は[プロジェクトボード](https://github.com/orgs/SereneTeam/projects/2)を確認してください。

## ブランチ
主要なブランチは以下のとおりです。これ以外のブランチは一時的なものや特定の用途で使われているものです。

| [master](https://github.com/SereneTeam/alterlinux/tree/master) |  [dev-stable](https://github.com/SereneTeam/alterlinux/tree/dev-stable) | [dev](https://github.com/SereneTeam/alterlinux/tree/dev) | [Japanese](https://github.com/SereneTeam/alterlinux/tree/Japanese) |
|:-----:|:-----:|:-----:|:-----:|
| 最も安定しています。バグの修正などは遅れる場合があります。 | 定期的に更新されます。比較的安定していて、最新の機能や修正を利用できます。 | 常に更新されます。問題が多数残っている場合があります。| 日本語版のAlterLinuxです。OS本体の更新は`master`に追従していますが、日本語独自の更新は遅れることがあります。 |

## リポジトリとソフトウェア

### リポジトリ
- [SereneTeam/alter-repo](https://github.com/SereneTeam/alter-repo)  
全てのミラーサーバはこのリポジトリと同期しています。  


### ソフトウェア
Alter Linuxに入っている独自のソフトウェアのソースコードは以下にあります。
パッケージ一覧は[こちら](https://github.com/SereneTeam/alterlinux/blob/master/packages.x86_64)にあります。  
すべての完全なパッケージ一覧はイメージファイル内にあります。

- [EG-Installer](https://github.com/Hayao0819/EG-Installer)([PKGBUILD](https://github.com/Hayao0819/EG-Installer-PKGBUILD))
- [plymouth-theme-alter](https://github.com/yamad-linuxer/plymouth-theme-alter)([PKGBUILD](https://github.com/Hayao0819/plymouth-theme-alter))
- [lightdm-webkit2-theme-alter](https://github.com/SereneTeam/lightdm-webkit2-theme-alter)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/unstable/lightdm-webkit2-theme-alter))
- [calamares](https://gitlab.manjaro.org/applications/calamares)([PKGBUILD](https://gitlab.manjaro.org/packages/extra/calamares))
- [alterlinux-calamares](https://github.com/SereneTeam/alterlinux-calamares)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/unstable/calamares))


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
```

#### コンテナ上でビルドする
Dockerでビルドする場合は、[この手順](Howtobuild_on_docker.md)を参照してください。

### ビルドウィザード
wizard.shを使用して簡単に思い通りの設定でビルドできます。bashで書かれていますのでターミナルから実行してください。  
「はい」か「いいえ」の質問は`y`か`n`で応えてください。数値を入力する場合は半角で入力してください。  

```bash
./wizard.sh
```

### build.shのオプション

#### 基本
通常はウィザードを使用してください。  
デフォルトパスワードは`alter`です。  
lymouthは無効化されています。  
デフォルトの圧縮方式は`zstd`です。  

```bash
./build.sh <options>
```

#### オプション
- Plymouthを有効化する ：   `-b`
- 圧縮方式を変える      ：   `-c <comp type>`
- カーネルを変更する     :   `-k <kernel>`
- パスワードを変更する   ：   `-p <password>`
- 圧縮のオプション      ：   `-t <options>`

##### 例
以下の条件でビルドするにはこのようにします。

- Plymouthを有効化
- 圧縮方式は`gzip`
- カーネルは`linux-lqx`
- パスワードは`ilovearch`

```bash
./build.sh -b -c "gzip" -k "lqx" -p 'ilovearch' 
```

##### カーネルについて
カーネルは現在、以下の種類がサポートされています。未指定の場合は通常の`linux`カーネルが使用されます。  
`-k`のオプションは必ず`linux-foo`の`foo`の部分を入れてください。例えば`linux-lts`の場合は`lts`が入ります。  
  
以下はサポートされている値とカーネルです。カーネルの説明は[ArchWiki](https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB)を引用しています。

- ck    : linux-ck にはシステムのレスポンスを良くするためのパッチが含まれています。
- lts   : `core`リポジトリにある長期サポート版 (Long term support, LTS) の Linux カーネルとモジュール。
- lqx   : デスクトップ・マルチメディア・ゲーム用途に Debian 用の設定と ZEN カーネルソースを使ってビルドされたディストロカーネル代替
- rt    : このパッチを使うことでカーネルのほとんど全てをリアルタイム実行できるようになります。
- zen   : `linux-zen`はカーネルハッカーたちの知恵の結晶です。日常的な利用にうってつけの最高の Linux カーネルになります。

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

## ドキュメント
- [パッケージリストについての注意](packages.md)
- [Docker上でビルドする方法](Howtobuild_on_docker.md)
- [新しいカーネルを追加する方法](Support_a_new_kernel.md)

## SereneTeamと開発者について
SereneTeamは主に中高生で構成されたLinuxディストリビューションの開発チームです。ほぼ全員が日本人で、メンバーは合計で24人います。  
Ubuntuをベースとした[SereneLinux](https://serenelinux.com)を開発、公開しています。  
私達はそのノウハウを活かし、Alter Linuxの開発に取り組んでいます。  

### Twitter アカウント
主要な開発メンバーのTwitterへのリンクです。  
このアカウントでの発言はすべてSereneTeam公式のものではなく、あくまでも開発者個人のものとします。  

#### 公式
以下は公式のアカウントです。
- [Alter Linux](https://twitter.com/AlterLinux)
- [SereneLinux Global](https://twitter.com/SereneLinux)
- [SereneLinux JP](https://twitter.com/SereneDevJP)

#### 開発者
主な開発メンバーのTwitterへのリンクです。  
このアカウントで行われたすべての発言はSereneTeamの公式ではなく、開発者個人の見解です。  

##### 開発担当
- [Hayao0819](https://twitter.com/Hayao0819)
- [lap1sid](https://twitter.com/Pixel_3a)
- [yamad](https://twitter.com/yamad_linuxer)

##### デザイン担当
- [tukutun](https://twitter.com/tukutuN_27)