<!-- LLM Generated: This document was created by Claude -->

# コンフィグの仕様

本ドキュメントでは、alteriso の設定ファイル `profiledef.json` の仕様について説明します。

## ファイル形式

`profiledef.json` は JSON 形式のファイルで、alteriso プロファイルの設定を定義します。

## フィールド仕様

### 必須フィールド

#### arch

- **型**: string
- **説明**: ターゲットアーキテクチャ
- **デフォルト値**: なし (必須)
- **例**: `"x86_64"`

現在サポートされているアーキテクチャ:

- `x86_64`

#### modules

- **型**: string[]
- **説明**: 使用するモジュールのリスト
- **デフォルト値**: なし (必須)
- **例**: `["base", "user", "network-manager"]`

指定された順序でモジュールがロードされます。
モジュール名は `modules/` ディレクトリのディレクトリ名と一致する必要があります。

### オプションフィールド

#### os_name

- **型**: string
- **説明**: OS の表示名
- **デフォルト値**: `""`
- **例**: `"Alter Linux"`

ブートローダー設定などで使用されます。
`%ALTERISO_OS_NAME%` プレースホルダーに展開されます。

#### kernel_name

- **型**: string
- **説明**: カーネルパッケージ名
- **デフォルト値**: `"linux"`
- **例**: `"linux"`, `"linux-lts"`, `"linux-zen"`

使用するカーネルパッケージを指定します。
`%ALTERISO_KERNEL_NAME%` プレースホルダーに展開されます。

#### username

- **型**: string
- **説明**: ライブ環境のユーザー名
- **デフォルト値**: `""`
- **例**: `"live"`

`user` モジュールなどで使用されます。

#### cow_spacesize

- **型**: string
- **説明**: Copy-on-Write 領域のサイズ
- **デフォルト値**: `"256M"`
- **例**: `"1G"`, `"512M"`, `"2G"`

ライブ環境で書き込み可能な領域のサイズを指定します。
`%ALTERISO_COW_SPACESIZE%` プレースホルダーに展開されます。

#### injects

- **型**: object (`map[string][]string`)
- **説明**: プロファイルレベルのインジェクション定義
- **デフォルト値**: `{}`
- **例**:

```json
{
    "injects": {
        "post__make_packages": [
            "custom_post_install"
        ]
    }
}
```

プロファイル固有のインジェクション関数を定義します。
モジュールのインジェクションの後に実行されます。

## 設定例

### 最小限の設定

```json
{
    "arch": "x86_64",
    "modules": ["base"]
}
```

### 標準的な設定

```json
{
    "os_name": "My Custom Linux",
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

### 完全な設定例

```json
{
    "os_name": "Alter Linux",
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
    "cow_spacesize": "1G",
    "injects": {
        "post__make_customize_airootfs": [
            "custom_setup_function"
        ]
    }
}
```

## プレースホルダー展開

設定値は、ブートローダー設定ファイルなどのプレースホルダーに展開されます。

### 利用可能なプレースホルダー

| プレースホルダー         | 対応する設定                         | デフォルト値 |
| ---                      | ---                                    | ---          |
| `%ALTERISO_OS_NAME%`     | `os_name`                              | `""`       |
| `%ALTERISO_KERNEL_NAME%` | `kernel_name`                          | `"linux"`  |
| `%ALTERISO_COW_SPACESIZE%` | `cow_spacesize`                      | `"256M"`   |
| `%ALTERISO_KERNEL_PARAM%` | モジュールの `append_kernel_param`   | `""`       |

### 展開の例

#### ブートローダー設定テンプレート

```text
LABEL %ALTERISO_OS_NAME%
LINUX /boot/vmlinuz-%ALTERISO_KERNEL_NAME%
APPEND cow_spacesize=%ALTERISO_COW_SPACESIZE% %ALTERISO_KERNEL_PARAM%
```

#### 設定

```json
{
    "os_name": "Custom Linux",
    "kernel_name": "linux-lts",
    "cow_spacesize": "2G"
}
```

#### 展開結果

```text
LABEL Custom Linux
LINUX /boot/vmlinuz-linux-lts
APPEND cow_spacesize=2G quiet splash
```

## モジュールとの関係

### modules フィールド

`modules` で指定されたモジュールは、以下の要素を提供します:

1. **パッケージリスト** - `packages.x86_64.d/` からマージ
2. **ファイル** - `airootfs.any/` と `airootfs.x86_64/` からマージ
3. **スクリプト** - `load_scripts` で指定されたスクリプトを読み込み
4. **インジェクション** - `injects` で定義された関数を登録
5. **カーネルパラメータ** - `append_kernel_param` を連結

### モジュールのロード順序

モジュールは `modules` 配列の順序でロードされます。

```json
{
    "modules": ["base", "user", "network-manager"]
}
```

この場合:

1. `base` モジュールがロード
2. `user` モジュールがロード
3. `network-manager` モジュールがロード

インジェクション関数やファイルの上書きは、この順序で処理されます。

## バリデーション

### 必須フィールドのチェック

`arch` と `modules` は必須です。これらが欠けている場合、エラーになります。

### モジュールの存在チェック

`modules` に指定されたモジュールが `modules/` ディレクトリに存在しない場合、エラーになります。

### JSON 形式のチェック

JSON の形式が不正な場合、パースエラーが発生します。

## スクリプトからの参照

### __alteriso_profiledef 関数

`profiledef.json` の内容を JSON として取得できます。

```bash
__alteriso_profiledef
```

出力例:

```json
{"os_name":"Alter Linux","arch":"x86_64","modules":["base","user"],...}
```

### 個別フィールドの取得関数

特定のフィールド値を取得する便利関数も提供されています。

```bash
__alteriso_profiledef_kernelname    # kernel_name を取得
__alteriso_profiledef_username      # username を取得
__alteriso_profiledef_osname        # os_name を取得
```

### 使用例

```bash
#!/usr/bin/env bash

# カーネル名を取得
kernel_name=$(__alteriso_profiledef_kernelname)
echo "Using kernel: ${kernel_name}"

# ユーザー名を取得
username=$(__alteriso_profiledef_username)
echo "Creating user: ${username}"

# jq を使って任意のフィールドを取得
cow_size=$(__alteriso_profiledef | jq -r '.cow_spacesize')
echo "COW space size: ${cow_size}"
```

## 設定のベストプラクティス

### 1. モジュールの最小化

必要なモジュールのみを `modules` に含めます。

```json
{
    "modules": ["base", "user"]
}
```

### 2. 適切な COW サイズ

用途に応じて `cow_spacesize` を設定します:

- ミニマル環境: `"512M"`
- 標準環境: `"1G"`
- デスクトップ環境: `"2G"` 以上

### 3. カーネルの選択

用途に応じたカーネルを選択します:

- 標準: `"linux"`
- 長期サポート: `"linux-lts"`
- 低レイテンシ: `"linux-zen"`
- ハードウェア互換性: `"linux-hardened"`

### 4. OS 名の設定

わかりやすい OS 名を設定します:

```json
{
    "os_name": "My Linux Distribution"
}
```

## トラブルシューティング

### JSON パースエラー

```text
Error: failed to parse profile config: invalid character...
```

解決方法:

- JSON の形式を確認 (カンマ、括弧、引用符など)
- JSON バリデータでチェック

### モジュールロードエラー

```text
Error: failed to load module <name>: module directory does not exist
```

解決方法:

- `modules/` ディレクトリに該当モジュールが存在するか確認
- モジュール名のスペルを確認

### フィールド型エラー

```text
Error: json: cannot unmarshal...
```

解決方法:

- フィールドの型を確認 (string, array, object)
- 配列は `[]`、文字列は `""` で囲む

## 参考

- モジュールの詳細: [module.md](module.md)
- 使い方の詳細: [usage.md](usage.md)
