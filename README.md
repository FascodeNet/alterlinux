
## AlterLinux - 誰でも使えることを目標にした日本製のArchLinux派生のOS

![License](https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=appveyor)
![Base](https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=appveyor)
![archiso](https://img.shields.io/badge/archiso--version-43--1-blue?style=for-the-badge&logo=appveyor)

## 概要
  
Alter LinuxはArch Linuxをベースに開発されている新しいOSです。  


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
ArchLinux環境でビルドする必要があります。  
事前に`archiso`パッケージをインストールしておいてください。

```bash
git clone https://github.com/SereneTeam/alterlinux.git
cd alterlinux
./build.sh
```

### build.shのオプション

#### 基本
そのまま実行してください。デフォルトパスワードは`alter`です。Plymouthは無効化されています。

#### オプション
- Plymouthを有効化する ： `-b`
- パスワードを変更する ： `-p <password>`

例 ： Plymouthを有効化し、パスワードを`ilovearch`に変更する。

```bash
./build.sh -b -p 'ilovealter'
```


#### Plymouthについて
`build.sh`に`-b`をつけるとPlymouthが有効化されます。  
ただし、現在Plymouthを有効化した状態だとインストール後に正常に起動しない問題が確認されています。

#### ライブ環境でのパスワード
デフォルトのパスワードは`alter`です。  
`build.sh`に`-p [password]`とすることでパスワードを変更できます。  
オプション無しでパスワードを変更する場合は`build.sh`の`password`の値を変更してください。