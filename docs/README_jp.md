
## Alter Linux - 誰でも使えることを目標にした日本製でArch Linux派生のOS

![AlterLogo](../images/logo.png)

[![License](https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=gnu)](../LICENSE)
[![Base](https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=arch-linux)](https://www.archlinux.org/)
[![archiso](https://img.shields.io/badge/archiso--version-43--1-blue?style=for-the-badge&logo=appveyor)](https://git.archlinux.org/archiso.git/tag/?h=v43)
[![Release](https://img.shields.io/github/v/release/SereneTeam/alterlinux?color=blue&include_prereleases&style=for-the-badge)](https://github.com/SereneTeam/alterlinux/releases)

| [日本語](README_jp.md) | [English](README.md) |
|:-----:|:-----:|

## 概要

Alter LinuxはArch Linuxをベースに開発されている新しいOSです。  
Xfce4による洗練されたUIとGUIで完結するパッケージ管理ツールを兼ね備え、誰でも簡単に高速で最新のOSを使用できます。  
AlterLinuxの最新の状況は[プロジェクトボード](https://github.com/orgs/SereneTeam/projects/2)を確認してください。

## ブランチ
主要なブランチは以下のとおりです。これ以外のブランチは一時的なものや特定の用途で使われているものです。
以前に使用されていたJapaneseブランチは削除されました。

[master](https://github.com/SereneTeam/alterlinux/tree/master) | [dev-stable](https://github.com/SereneTeam/alterlinux/tree/dev-stable) | [dev](https://github.com/SereneTeam/alterlinux/tree/dev)
--- | --- | ---
最も安定しています。バグの修正などは遅れる場合があります。 | 定期的に更新されます。比較的安定していて、最新の機能や修正を利用できます。 | 常に更新されます。問題が多数残っている場合があります。

## 意見や感想について
もしAlterLinuxが起動しなかったり、使いにくかったり、標準でインストールしてほしいソフトウェアがあったら、遠慮なく[Issue](https://github.com/SereneTeam/alterlinux/issues)に投稿して下さい。  
私達はAlterLinuxをより良いものにするために様々なユーザーの意見を募集しています。

## Twitter アカウント
主要な開発メンバーのTwitterへのリンクです。  
このアカウントでの発言はすべてSereneTeam公式のものではなく、あくまでも開発者個人のものとします。  

### 公式
以下は公式のアカウントです。
- [Alter Linux](https://twitter.com/AlterLinux)
- [SereneLinux Global](https://twitter.com/SereneLinux)
- [SereneLinux JP](https://twitter.com/SereneDevJP)

### 開発者
主な開発メンバーのTwitterへのリンクです。  
このアカウントで行われたすべての発言はSereneTeamの公式ではなく、開発者個人の見解です。  

<h5 align="center">開発担当</h5>
<p align="center">
<b><a><a href="https://twitter.com/Hayao0819"><img src="https://avatars1.githubusercontent.com/u/32128205" width="100px" /></a></b>
<b><a><a href="https://twitter.com/Pixel_3a"><img src="https://avatars0.githubusercontent.com/u/48173871" width="100px" /></a></b>
<b><a><a href="https://twitter.com/yangniao23"><img src="https://avatars0.githubusercontent.com/u/47053316" width="100px" /></a></b>
<b><a><a href="https://twitter.com/yamad_linuxer"><img src="https://avatars1.githubusercontent.com/u/45691925" width="100px" /></a></b>
</p>


<h5 align="center">デザイン担当</h5>
<p align="center">
<b><a><a href="https://twitter.com/tukutuN_27"><img src="https://0e0.pw/5yuH" width="100px" /></a></b>
</p>

## リポジトリとソフトウェア
リポジトリのパッケージを使用するには鍵を追加する必要があります。  
以下のコマンドを実行して鍵を追加して下さい。

```bash
curl https://山d.com/repo/fascode.pub | sudo pacman-key -a -
sudo pacman-key --lsign-key development@fascode.net
```

### リポジトリ
以前まで使用されていたGitHubのリポジトリは現在は使用されていません。現在は[こちらのサーバ](https://xn--d-8o2b.com/repo/)が最新のリポジトリです。


### ソフトウェア
ほとんどのパッケージは公式パッケージか、AUR上に公開していますが、一部のものはどちらにもありません。そのようなパッケージのソースコードとPKGBUILDへのリンクを以下に記載します。  
バイナリファイルが必要な場合は[AlterLinuxリポジトリ](https://xn--d-8o2b.com/repo/alter-stable/x86_64/)にアクセスして下さい。

- [alterlinux-calamares](https://github.com/SereneTeam/alterlinux-calamares)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/unstable/calamares))
- [alterlinux-fcitx-conf](https://github.com/SereneTeam/alterlinux-fcitx-conf)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-fcitx-conf))
- [alterlinux-keyring](https://github.com/SereneTeam/alterlinux-keyring)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-keyring))
- [alterlinux-mirrorlist](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-mirrorlist)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-mirrorlist))
- [alterlinux-wallpapers](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-wallpapers)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-wallpapers))
- [alterlinux-xfce-conf](https://github.com/SereneTeam/alterlinux-xfce-conf)([PKGBUILD](https://github.com/SereneTeam/alterlinux-pkgbuilds/tree/master/stable/alterlinux-xfce-conf))


## ビルド

以下の手順は、実機のArchLinuxでビルドするためのものです。

### 準備

ビルドは実機のArch Linuxを利用する方法とDocker上でビルドする方法があります。  
`build.sh`のオプションは共通です。  

### 実機でビルドする
実機でビルドする場合はArchLinux環境でビルドする必要があります。  
AlterLinuxのリポジトリを使用するために鍵を追加する必要があります。鍵を追加する方法は上記記載されています。

ビルドに必要なパッケージをインストールして下さい。

```bash
sudo pacman -S git make arch-install-scripts squashfs-tools libisoburn dosfstools lynx
```
そしてソースコードをダウンロードしてください。

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

### コンテナ上でビルドする
Dockerでビルドする場合は、[この手順](Howtobuild_on_docker.md)を参照してください。

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
用途 | 使い方
--- | ---
ブートスプラッシュを有効化 | -b
カーネルを変える | -k [kernel]
パスワードを変更する | -p [password]
日本語にする | -j
圧縮方式を変更する | -c [comp type]
圧縮のオプションを設定する | -t [comp option]
出力先ディレクトリを指定する| -o [dir]
作業ディレクトリを指定する | -w [dir]


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

## 起動できない場合
ブート時のアニメーションを無効化してブートし、ログを確認することができます。  
ディスクから起動し、`Boot Alter Linux without boot splash (x86_64)`を選択して下さい。


## SereneTeamと開発者について
SereneTeamは主に中高生で構成されたLinuxディストリビューションの開発チームです。ほぼ全員が日本人で、メンバーは合計で24人います。  
Ubuntuをベースとした[SereneLinux](https://serenelinux.com)を開発、公開しています。  
私達はそのノウハウを活かし、Alter Linuxの開発に取り組んでいます。  
