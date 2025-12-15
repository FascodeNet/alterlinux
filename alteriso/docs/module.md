# モジュールの仕組みと仕様

本ドキュメントでは、alteriso のモジュールシステムの仕組みと仕様について説明します。

## 概要

モジュールは、alteriso の中核となる機能単位です。
各モジュールは独立したディレクトリとして存在し、パッケージリスト、ファイル、スクリプト、インジェクション関数などを提供します。

## モジュールの構造

### ディレクトリ構成

```
modules/<module_name>/
├── alteriso.json           # モジュール設定ファイル (必須)
├── module.sh               # シェルスクリプト (オプション)
├── packages.x86_64.d/      # パッケージリスト (オプション)
│   └── *.x86_64
├── bootstrap_packages.x86_64  # bootstrap用パッケージ (オプション)
├── airootfs.any/           # 全アーキテクチャ共通ファイル (オプション)
│   └── (ルートファイルシステム構造)
└── airootfs.x86_64/        # アーキテクチャ固有ファイル (オプション)
    └── (ルートファイルシステム構造)
```

### alteriso.json の仕様

モジュールの設定を定義する JSON ファイルです。

#### 必須フィールド

- `manifest_version` (number) - マニフェストバージョン (現在は `1` のみサポート)
- `module_version` (number) - モジュールのバージョン番号

#### オプションフィールド

- `load_scripts` (string[]) - 読み込むシェルスクリプトファイルのリスト
- `injects` (object) - mkarchiso 関数へのインジェクション定義
- `append_kernel_param` (string[]) - カーネルパラメータに追加する文字列のリスト

#### 例

```json
{
    "manifest_version": 1,
    "module_version": 1,
    "load_scripts": ["module.sh"],
    "injects": {
        "post__make_custom_airootfs": [
            "__alteriso_base_setup_mkinitcpio_presets"
        ]
    },
    "append_kernel_param": ["quiet", "splash"]
}
```

## モジュールのロード

### ロードプロセス

1. `profiledef.json` の `modules` フィールドに指定されたモジュールが順番にロードされる
2. 各モジュールの `alteriso.json` が読み込まれる
3. `manifest_version` が検証される (現在は `1` のみサポート)
4. モジュールの設定が Profile 構造体に統合される

### エラーハンドリング

以下の場合、モジュールのロードは失敗します:

- モジュールディレクトリが存在しない
- `alteriso.json` が存在しない
- `alteriso.json` の JSON が不正
- `manifest_version` がサポートされていない値

## インジェクション機構

### 仕様

`injects` フィールドで、mkarchiso の関数に対するフック関数を定義できます。

```json
{
    "injects": {
        "<フック名>": [
            "<関数名1>",
            "<関数名2>"
        ]
    }
}
```

- キー: フック名 (`pre_<function>`, `post_<function>`, `override_<function>`)
- 値: 実行する関数名の配列 (配列の順序で実行される)

### 複数モジュールからのインジェクション

複数のモジュールが同じフックに関数を登録した場合、モジュールのロード順序で実行されます。

例:
- モジュール A: `post__make_packages` → `[function_a]`
- モジュール B: `post__make_packages` → `[function_b]`

実行順序: `function_a` → `function_b`

### スクリプトのロード

`load_scripts` で指定されたスクリプトファイルは、生成される `profiledef.sh` に埋め込まれます。

## パッケージリスト

### packages.x86_64.d/

このディレクトリ内の `*.x86_64` ファイルに記載されたパッケージがインストールされます。

#### ファイル形式

- 1行に1パッケージ名を記載
- `#` で始まる行はコメント
- 空行は無視される

#### 例

```
# ネットワーク管理
networkmanager
nm-connection-editor

# GUI ツール
network-manager-applet
```

### パッケージのマージ

プロファイル生成時、以下の順序でパッケージリストがマージされます:

1. すべてのモジュールの `packages.x86_64.d/*.x86_64`
2. プロファイルの `packages.x86_64.d/*.x86_64`

重複するパッケージは自動的に削除され、最終的なリストはソートされます。

### bootstrap_packages.x86_64

bootstrap ビルドモード用のパッケージリストです。
書式は `packages.x86_64.d/` と同じです。

## ファイルシステムオーバーレイ

### airootfs.any と airootfs.x86_64

これらのディレクトリは、ISO の rootfs に直接コピーされるファイルを格納します。

- `airootfs.any/` - すべてのアーキテクチャで使用
- `airootfs.x86_64/` - x86_64 アーキテクチャ専用

### マージ順序

以下の順序でファイルがコピーされ、後のものが前のものを上書きします:

1. モジュール1の `airootfs.any/`
2. モジュール1の `airootfs.x86_64/`
3. モジュール2の `airootfs.any/`
4. モジュール2の `airootfs.x86_64/`
5. ...
6. プロファイルの `airootfs.any/`
7. プロファイルの `airootfs.x86_64/`

### ファイル構造の例

```
airootfs.any/
├── etc/
│   ├── systemd/
│   │   └── system/
│   │       └── custom.service
│   └── skel/
│       └── .bashrc
└── usr/
    └── share/
        └── custom/
            └── config.conf
```

## カーネルパラメータ

### append_kernel_param

ブートローダー設定に追加するカーネルパラメータを指定します。

```json
{
    "append_kernel_param": ["quiet", "splash", "loglevel=3"]
}
```

すべてのモジュールの `append_kernel_param` が連結され、ブートローダー設定ファイルの
`%ALTERISO_KERNEL_PARAM%` プレースホルダーに展開されます。

## モジュールの作成

### 基本手順

1. `modules/` ディレクトリに新しいディレクトリを作成
2. `alteriso.json` を作成し、必須フィールドを定義
3. 必要に応じてパッケージリスト、ファイル、スクリプトを追加
4. `profiledef.json` の `modules` に追加

### 最小限のモジュール例

```json
{
    "manifest_version": 1,
    "module_version": 1
}
```

このモジュールは何も提供しませんが、有効なモジュールです。

### パッケージのみを提供するモジュール例

```
modules/example/
├── alteriso.json
└── packages.x86_64.d/
    └── example.x86_64
```

`alteriso.json`:
```json
{
    "manifest_version": 1,
    "module_version": 1
}
```

`packages.x86_64.d/example.x86_64`:
```
vim
tmux
git
```

### インジェクション付きモジュール例

```
modules/custom/
├── alteriso.json
└── module.sh
```

`alteriso.json`:
```json
{
    "manifest_version": 1,
    "module_version": 1,
    "load_scripts": ["module.sh"],
    "injects": {
        "post__make_packages": ["custom_post_install"]
    }
}
```

`module.sh`:
```bash
custom_post_install() {
    _msg_info "Running custom post-install tasks..."
    # カスタム処理
}
```

## 利用可能な変数

モジュールのスクリプト内では、以下の alteriso 専用変数にアクセスできます:

### プロファイル情報取得関数

- `__alteriso_profiledef` - profiledef.json の内容を JSON として出力
- `__alteriso_profiledef_kernelname` - カーネル名を取得
- `__alteriso_profiledef_username` - ユーザー名を取得
- `__alteriso_profiledef_osname` - OS名を取得

### 使用例

```bash
local kernel_name=$(__alteriso_profiledef_kernelname)
local username=$(__alteriso_profiledef_username)

echo "Kernel: ${kernel_name}"
echo "Username: ${username}"
```

## 標準モジュール

alteriso には以下の標準モジュールが含まれています:

- `base` - 基本機能 (mkinitcpio 設定など)
- `user` - ユーザーアカウント作成
- `network-manager` - NetworkManager のインストール
- `lightdm` - LightDM ディスプレイマネージャー
- `gdm` - GDM ディスプレイマネージャー
- `plymouth` - ブートスプラッシュ
- `livecd-sound` - ライブCD用サウンド設定

詳細は各モジュールのソースコードを参照してください。
