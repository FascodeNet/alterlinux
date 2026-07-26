<!-- LLM Generated: This document was created by Codex -->

# プロファイル設定

この文書は、alteriso の入力プロファイルと `profiledef.json` の仕様を説明します。
実行方法は [usage.md](usage.md)、モジュール固有の仕様は [module.md](module.md) を参照してください。

## ディレクトリ構成

```text
configs/<name>/
├── profiledef.json             # alteriso 設定（必須）
├── profiledef.sh               # archiso 設定（必須）
├── pacman.conf                 # Pacman 設定
├── pacman.conf.any
├── pacman.conf.<arch>          # アーキテクチャ固有 Pacman 設定
├── packages                    # 共通パッケージ一覧
├── packages.d/
├── packages.any
├── packages.any.d/
├── packages.<arch>
├── packages.<arch>.d/
├── bootstrap_packages
├── bootstrap_packages.d/
├── bootstrap_packages.any
├── bootstrap_packages.any.d/
├── bootstrap_packages.<arch>
├── bootstrap_packages.<arch>.d/
├── airootfs/
├── airootfs.any/
├── airootfs.<arch>/
├── splash.png
└── <bootloader>/               # 共有ブートローダーディレクトリの置き換え
```

`profiledef.sh` は通常の archiso プロファイル設定です。alteriso は生成時にローダーと
モジュールスクリプトを加えた `profiledef.sh` を作り、元ファイル自体は変更しません。

## profiledef.json

### 必須フィールド

| フィールド | 型 | 説明 |
| --- | --- | --- |
| `arch` | string | デフォルトのターゲットアーキテクチャ |
| `modules` | string[] | 読み込むモジュール名。空配列は有効 |

`arch` は空でない具体的な名前である必要があります。固定の許可リストはありませんが、
モジュール、パッケージリポジトリ、archiso のすべてが対象アーキテクチャに対応している必要が
あります。モジュール用のワイルドカード `"any"` は指定できません。

`modules` の要素は `--modules` で指定したディレクトリ直下の名前です。空文字列、
前後の空白、パス、重複した名前は拒否されます。

### オプションフィールド

| フィールド | 型 | 未指定時 | 用途 |
| --- | --- | --- | --- |
| `os_name` | string | `""` | ブートローダーの `%ALTERISO_OS_NAME%` |
| `kernel_name` | string | `""` | `%ALTERISO_KERNEL_NAME%` と `base` モジュール |
| `username` | string | `""` | `user` モジュールとディスプレイマネージャーモジュール |
| `cow_spacesize` | string | `""` | `%ALTERISO_COW_SPACESIZE%` |
| `injects` | object (`map[string][]string`) | 空 | プロファイル固有のインジェクション |
| `require_injectable` | boolean | `false` | インジェクション非対応の mkarchiso での実行を拒否 |
| `pacman_conf` | string | 自動選択 | 使用する Pacman 設定の基準パス |

これらの値に暗黙の `"linux"` や `"256M"` は補われません。必要な値はプロファイル側で
明記してください。現在の Go データモデルにない JSON フィールドは生成後の `profiledef.json`
には保持されないため、上表以外のフィールドには依存しないでください。

### 例

```json
{
    "arch": "x86_64",
    "modules": [
        "base",
        "network-manager",
        "user"
    ],
    "os_name": "Example Linux",
    "kernel_name": "linux",
    "username": "live",
    "cow_spacesize": "1G",
    "require_injectable": true
}
```

## 生成対象の選択

一つの archiso プロファイルが持つターゲットは一つです。生成時の対象は次の順で決まります。

1. `--arch` の値
2. `profiledef.json` の `arch`

選択後に、すべてのモジュールがそのアーキテクチャを受け入れるか検証されます。`--arch` は
入力を変更しないため、同じ入力プロファイルから別々の出力先へ複数回生成できます。

出力先は重複させないでください。`profile generate` は既存の出力ディレクトリを拒否します。
実行例は [usage.md](usage.md#profile-共通オプション) を参照してください。

## Pacman 設定の選択

`pacman_conf` が指定されている場合、相対パスはプロファイルディレクトリを基準に解決されます。
指定値を基準パスとして、次の優先順位で一つを選びます。

1. `<基準パス>.<arch>`
2. `<基準パス>.any`
3. `<基準パス>`

未指定の場合の基準パスは `pacman.conf` なので、選択順は次のとおりです。

1. `pacman.conf.<arch>`
2. `pacman.conf.any`
3. `pacman.conf`

選択されたファイルが存在しなければ生成は失敗します。

## パッケージとオーバーレイ

プロファイルでもモジュールと同じ命名規則を使用できます。

- `packages`、`packages.d/*`: 拡張子なしの共通レイヤー
- `packages.any`、`packages.any.d/*`: 明示的な全ターゲット共通レイヤー
- `packages.<arch>`、`packages.<arch>.d/*`: 選択したターゲット専用レイヤー
- `bootstrap_packages*`: 同じ規則のブートストラップ用一覧
- `airootfs/`: 拡張子なしの共通レイヤー
- `airootfs.any/`: 明示的な全ターゲット共通レイヤー
- `airootfs.<arch>/`: 選択したターゲット専用レイヤー

3 種類はすべて読み込まれます。マージ順やファイル形式、`!` による除外構文は [module.md](module.md) にまとめています。

## ブートローダー設定

`--bootloaders` の直下にある各ディレクトリが出力へコピーされます。同名のディレクトリが
入力プロファイルにある場合は、共有版全体の代わりにプロファイル側のものを使います。
`splash.png` がある場合は、生成後の `syslinux/splash.png` を置き換えます。

コピー時に次のプレースホルダーを展開します。

| プレースホルダー | 値 |
| --- | --- |
| `%ALTERISO_OS_NAME%` | `os_name` |
| `%ALTERISO_KERNEL_NAME%` | `kernel_name` |
| `%ALTERISO_COW_SPACESIZE%` | `cow_spacesize` |
| `%ALTERISO_KERNEL_PARAM%` | モジュールの `append_kernel_param` |

archiso 自身が処理する `%ARCH%`、`%INSTALL_DIR%` などはそのまま残ります。

## 検証

生成前に少なくとも次を検証します。

- `profiledef.json` が正しい JSON である
- `arch` と `modules` が前述の制約を満たす
- 指定されたモジュールが読み込める
- 選択したアーキテクチャを全モジュールが受け入れる
- プロファイル、ブートローダー、`profiledef.sh`、選択した Pacman 設定が存在する

## 生成された profiledef.json の参照

モジュールスクリプトでは次のシェルヘルパーを利用できます。

- `__alteriso_profiledef`
- `__alteriso_profiledef_arch`
- `__alteriso_profiledef_modules`
- `__alteriso_profiledef_kernelname`
- `__alteriso_profiledef_username`

任意のフィールドは `__alteriso_profiledef | jq ...` で参照できます。
