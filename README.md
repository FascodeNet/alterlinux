![License](https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=appveyor)
![Base](https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=appveyor)
![archiso](https://img.shields.io/badge/archiso--version-43--1-blue?style=for-the-badge&logo=appveyor)

# 概要
  
Alter LinuxはArch Linuxをベースに開発されている新しいOSです。  

# ビルド
ArchLinux環境でビルドする必要があります。  
事前に`archiso`パッケージをインストールしておいてください。

```bash
git clone https://github.com/SereneTeam/alterlinux.git
cd alterlinux
./build -v
```

# Plymouthについて
`build.sh`に`-b`をつけるとPlymouthが有効化されます。  
（現在`plymouth`ブランチでのみ利用可能です。）

# ライブ環境でのパスワード
デフォルトのパスワードは`alter`です。  
`build.sh`に`-p [password]`とすることでパスワードを変更できます。  
オプション無しでパスワードを変更する場合は`build.sh`の`password`の値を変更してください。