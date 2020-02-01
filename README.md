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
`build`スクリプトに`-p`をつけるとPlymouthが有効化されます。  
（現在`plymouth`ブランチでのみ利用可能です。）