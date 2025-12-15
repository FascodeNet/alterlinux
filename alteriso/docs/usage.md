# alteriso の基本的な使い方

本ドキュメントでは、alteriso の基本的な使い方について説明します。

## 概要

alteriso は、archiso のプロファイルを生成し、mkarchiso でビルド可能な形式に変換するツールです。

## 基本的なワークフロー

```
1. プロファイル作成 (profiledef.json)
2. gen.sh でプロファイル生成
3. mkarchiso でビルド
```

## プロファイルの作成

### ディレクトリ構造

```
configs/<profile_name>/
├── profiledef.json         # alteriso 設定 (必須)
├── profiledef.sh           # archiso 設定 (必須)
├── pacman.conf             # pacman 設定 (必須)
├── packages.x86_64.d/      # パッケージリスト (オプション)
│   └── *.x86_64
└── airootfs.any/           # ファイルオーバーレイ (オプション)
    └── (ルートファイルシステム構造)
```

### profiledef.json の作成

alteriso 用の設定ファイルです。

```json
{
    "os_name": "My Custom OS",
    "arch": "x86_64",
    "modules": [
        "base",
        "user",
        "network-manager"
    ],
    "kernel_name": "linux",
    "username": "live",
    "cow_spacesize": "1G"
}
```

### profiledef.sh の作成

archiso 用の設定ファイルです。通常の archiso プロファイルと同じ形式です。

```bash
#!/usr/bin/env bash

iso_name="mycustomos"
iso_label="MYCUSTOMOS_$(date +%Y%m)"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
airootfs_image_type="squashfs"
```

### pacman.conf の作成

ISO ビルド時に使用する pacman 設定ファイルです。
通常の pacman.conf と同じ形式です。

## プロファイルの生成

### gen.sh の使用

```bash
./gen.sh configs/<profile_name>
```

これにより、`out/<profile_name>/` に mkarchiso 用のプロファイルが生成されます。

### 生成されるファイル

```
out/<profile_name>/
├── profiledef.sh           # 生成された archiso プロファイル
├── packages.x86_64         # マージされたパッケージリスト
├── pacman.conf             # コピーされた pacman.conf
├── airootfs/               # マージされたファイル
├── syslinux/               # ブートローダー設定
├── grub/                   # GRUB 設定
└── efiboot/                # UEFI ブート設定
```

## ISO のビルド

### mkarchiso の実行

生成されたプロファイルを mkarchiso でビルドします。

```bash
sudo mkarchiso -v -w work -o out out/<profile_name>
```

オプション:
- `-v` - 詳細モード
- `-w work` - 作業ディレクトリ
- `-o out` - 出力ディレクトリ

### build.sh の使用

alteriso には簡易ビルドスクリプトが用意されています。

```bash
./build.sh
```

このスクリプトは:
1. `gen.sh configs/xfce` を実行
2. `mkarchiso` でビルド

を自動的に行います。

## コマンドリファレンス

### gen.sh

プロファイルを生成します。

```bash
./gen.sh [options] <profile_directory>
```

内部的には以下を実行します:

```bash
go run ./src profile \
    --bootloaders ./bootloaders/ \
    --modules ./modules/ \
    generate \
    -o ./out \
    <profile_directory>
```

### clean.sh

生成されたファイルをクリーンアップします。

```bash
./clean.sh
```

`out/` ディレクトリ内の生成されたプロファイルを削除します。

## カスタマイズ

### モジュールの選択

`profiledef.json` の `modules` フィールドでモジュールを選択します。

```json
{
    "modules": [
        "base",
        "user",
        "network-manager",
        "lightdm",
        "plymouth"
    ]
}
```

使用可能なモジュールは `modules/` ディレクトリを参照してください。

### パッケージの追加

プロファイルの `packages.x86_64.d/` にパッケージリストを追加します。

```
configs/myprofile/packages.x86_64.d/custom.x86_64
```

内容:
```
firefox
chromium
libreoffice-fresh
```

### ファイルの追加

`airootfs.any/` または `airootfs.x86_64/` にファイルを配置します。

```
configs/myprofile/airootfs.any/etc/hostname
```

内容:
```
mycustomos
```

### ブートローダーのカスタマイズ

ブートローダー設定は `bootloaders/` ディレクトリからコピーされます。
プロファイル固有の設定が必要な場合は、生成後に `out/<profile>/` を編集します。

## トラブルシューティング

### ビルドエラー

#### モジュールが見つからない

```
Error: failed to load module <name>: module directory does not exist
```

解決方法:
- `modules/` ディレクトリに該当モジュールが存在するか確認
- `profiledef.json` のモジュール名が正しいか確認

#### マニフェストバージョンエラー

```
Error: unsupported manifest version: <version>
```

解決方法:
- モジュールの `alteriso.json` の `manifest_version` を `1` に設定

#### パッケージが見つからない

mkarchiso 実行時にパッケージが見つからない場合:

解決方法:
- `pacman.conf` のリポジトリ設定を確認
- パッケージ名が正しいか確認
- `pacman -Sy` でデータベースを更新

### クリーンビルド

問題が解決しない場合、クリーンビルドを試してください:

```bash
./clean.sh
rm -rf work/
./build.sh
```

## 例: 最小限のプロファイル

### ディレクトリ構成

```
configs/minimal/
├── profiledef.json
├── profiledef.sh
└── pacman.conf
```

### profiledef.json

```json
{
    "os_name": "Minimal OS",
    "arch": "x86_64",
    "modules": ["base"],
    "kernel_name": "linux",
    "username": "live",
    "cow_spacesize": "512M"
}
```

### profiledef.sh

```bash
#!/usr/bin/env bash

iso_name="minimal"
iso_label="MINIMAL_$(date +%Y%m)"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux')
airootfs_image_type="squashfs"
```

### ビルド

```bash
./gen.sh configs/minimal
sudo mkarchiso -v -w work -o out out/minimal
```

## 例: デスクトップ環境付きプロファイル

### profiledef.json

```json
{
    "os_name": "Desktop OS",
    "arch": "x86_64",
    "modules": [
        "base",
        "user",
        "network-manager",
        "lightdm",
        "plymouth"
    ],
    "kernel_name": "linux",
    "username": "live",
    "cow_spacesize": "2G"
}
```

### packages.x86_64.d/desktop.x86_64

```
# デスクトップ環境
xfce4
xfce4-goodies

# アプリケーション
firefox
thunar
xfce4-terminal

# フォント
noto-fonts
noto-fonts-cjk
```

### ビルド

```bash
./gen.sh configs/desktop
sudo mkarchiso -v -w work -o out out/desktop
```

## 次のステップ

- モジュールの仕組みを理解する: [module.md](module.md)
- 設定の詳細を確認する: [config.md](config.md)
