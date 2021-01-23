# Alteriso 4
## 概要
Archisoをベースに一から作り直しました。

## 機能
Arch Linux派生OSがビルドできます。

本家にない機能として、AURパッケージのビルド、チャンネルがあります。
## 使い方
シンプルver
```bash
sudo ./build.sh [channel name]
```
ram build(高速化ver 大容量のRAMを要求します)
```bash
sudo ./build.sh -w [tmp dir] [channel name]
```
## 内部構成
今までのAlterisoとは違いbuild.shはarchiso/mkarchisoにチャンネルのパスを渡すだけのwrapperです。<br />
実処理はほとんどがarchiso/mkarchisoに書いてあります。

AURの処理はsystem/aur.shに書いてあります。

## 開発者

<a href="https://twitter.com/Hayao0819">
    <img src="https://avatars1.githubusercontent.com/u/32128205" width="100px" title="Hayao0819">
</a>
<a href="https://twitter.com/Pixel_3a">
    <img src="https://avatars0.githubusercontent.com/u/48173871" width="100px" title="Pixel_3a">
</a>
<a href="https://twitter.com/yangniao23">
    <img src="https://avatars0.githubusercontent.com/u/47053316" width="100px" title="yangniao23">
</a>
<a href="https://twitter.com/Watasuke102">
    <img src="https://avatars3.githubusercontent.com/u/36789813" width="100px" title="Watasuke102">
</a>
<a href="https://mstdn.jp/@kokkiemouse">
    <img src="https://avatars0.githubusercontent.com/u/39451248" width="100px" title="kokkiemouse">
</a>
<a href="https://twitter.com/stmkza">
    <img src="https://avatars2.githubusercontent.com/u/15907797" width="100px" title="stmkza" >
</a>
<a href="https://twitter.com/yamad_linuxer">
    <img src="https://avatars1.githubusercontent.com/u/45691925" width="100px" title="yamad_linuxer">
</a>
<a href="https://twitter.com/tukutun27">
    <img src="https://pbs.twimg.com/profile_images/1278526049903497217/CGMY5KUr.jpg" width="100px" title="tukutun27">
</a>
<a href="https://twitter.com/naoko1010hh">
    <img src="https://avatars1.githubusercontent.com/u/50263013" width="100px" title="naoko1010hh">
</a>

## Special Thanks

<a href="https://twitter.com/s29kt_Tsukkun">
    <img src="https://avatars2.githubusercontent.com/u/74809846" width="100px" title="s29kt_Tsukkun">
</a>
<a href="https://twitter.com/sunset09160306">
    <img src="https://avatars1.githubusercontent.com/u/61398531" width="100px" title="sunset09160306">
</a>

