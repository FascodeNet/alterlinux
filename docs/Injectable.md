<!-- LLM Generated: This document was created by Claude -->

# Injectable archiso

本ドキュメントでは、mkarchiso に実装されている関数インジェクション機構の仕様について説明します。

## 概要

mkarchiso は `_run_once()` ヘルパー関数を介して、プロファイルから内部関数の動作を拡張・カスタマイズできるインジェクション機構を提供しています。

この機構により、mkarchiso のコード本体を変更することなく、ビルドプロセスの各段階に独自の処理を挿入できます。

## インジェクション仕様

### フックポイント

`_run_once` 経由で呼び出される任意の関数 `<function_name>` に対して、以下の3種類のフック関数を定義できます:

| フック名 | 実行タイミング | 説明 |
| --- | --- | --- |
| `pre_<function_name>` | 元の関数の**実行前** | 前処理を追加 |
| `override_<function_name>` | 元の関数の**代わり** | 元の関数を完全に置き換える |
| `post_<function_name>` | 元の関数の**実行後** | 後処理を追加 |

### 実行順序

フックが定義されている場合、以下の順序で実行されます:

1. `pre_<function_name>` (定義されている場合)
2. `override_<function_name>` (定義されている場合) **または** `<function_name>` (overrideが未定義の場合)
3. `post_<function_name>` (定義されている場合)

### 実行管理

各フックは1回のみ実行され、`${work_dir}/${run_once_mode}.<フック名>` というマーカーファイルによって実行済みかどうかが管理されます。

### 定義方法

プロファイルの `profiledef.sh` 内で、bash 関数として定義します:

```bash
pre_<function_name>() {
    # 前処理
}

override_<function_name>() {
    # 元の関数の置き換え
}

post_<function_name>() {
    # 後処理
}
```

## インジェクション可能な関数

mkarchiso 内で `_run_once` を通じて呼び出される関数がインジェクション対象です。主なものを以下に示します。

### 共通処理

- `_make_work_dir` - 作業ディレクトリの作成
- `_make_pacman_conf` - pacman.conf の生成
- `_make_packages` - パッケージのインストール
- `_make_version` - バージョンファイルの作成
- `_make_pkglist` - パッケージリストの生成
- `_cleanup_pacstrap_dir` - 一時ファイルのクリーンアップ

### ISO ビルドモード固有

- `_export_gpg_publickey` - GPG公開鍵のエクスポート
- `_make_custom_airootfs` - カスタムファイルのコピー
- `_make_customize_airootfs` - カスタマイズスクリプトの実行
- `_check_if_initramfs_has_ucode` - マイクロコードチェック
- `_make_boot_on_iso9660` - ブートファイルのコピー
- `_prepare_airootfs_image` - ファイルシステムイメージの作成
- `_build_iso_image` - ISO イメージの生成

### Bootstrap ビルドモード固有

- `_build_bootstrap_image` - bootstrap tarball の作成

### Netboot ビルドモード固有

- `_sign_netboot_artifacts` - 成果物への署名
- `_export_netboot_artifacts` - netboot 成果物のエクスポート

### ブートローダー関連

- `_make_bootmode_<bootmode>` - 各ブートモードの設定
- `_make_common_grubenv_and_loopbackcfg` - GRUB 共通設定
- `_make_common_bootmode_grub_cfg` - GRUB 設定ファイル生成
- `_make_boot_on_fat` - FAT イメージへのブートファイルコピー

### ファイルシステム作成

- `_mkairootfs_<type>` - 各イメージタイプ (squashfs, erofs, ext4) の作成処理

### ビルドモード制御

- `_build_buildmode_<buildmode>` - 各ビルドモード (iso, bootstrap, netboot) の実行制御

完全なリストは mkarchiso のソースコードを参照してください。

## 利用可能な変数

フック関数内では、mkarchiso が定義するグローバル変数にアクセスできます:

### パス関連

- `${work_dir}` - 作業ディレクトリのパス
- `${pacstrap_dir}` - pacstrap 先のルートファイルシステムパス
- `${isofs_dir}` - ISO ファイルシステムのディレクトリパス
- `${profile}` - プロファイルディレクトリのパス

### ビルド設定

- `${arch}` - アーキテクチャ (例: `x86_64`)
- `${buildmode}` - ビルドモード (`iso`, `bootstrap`, `netboot`)
- `${run_once_mode}` - 現在の実行モード (通常は `${buildmode}` と同じ)

### ISO メタデータ

- `${iso_name}` - ISO 名
- `${iso_version}` - ISO バージョン
- `${iso_label}` - ISO ラベル
- `${install_dir}` - ISO 内のインストールディレクトリ (通常 `arch`)

その他の変数については mkarchiso のソースコードを参照してください。

## 利用可能なヘルパー関数

mkarchiso が提供する主なヘルパー関数:

- `_msg_info <message>` - 情報メッセージの出力
- `_msg_warning <message>` - 警告メッセージの出力
- `_msg_error <message> <exit_code>` - エラーメッセージの出力 (オプションで終了)

## 使用例

### 例1: パッケージインストール後の追加処理

```bash
post__make_packages() {
    _msg_info "Installing additional packages..."
    pacman --config "${work_dir}/${buildmode}.pacman.conf" \
           --noconfirm -r "${pacstrap_dir}" -S custom-package
}
```

### 例2: カスタマイズスクリプト実行前の準備

```bash
pre__make_customize_airootfs() {
    _msg_info "Preparing customization environment..."
    install -d -m 0755 "${pacstrap_dir}/root/.config"
}
```

## 注意事項

### 1. ビルドモードごとの独立実行

`run_once_mode` 変数により、各ビルドモード (`iso`, `bootstrap`, `netboot`) でフックは独立して実行されます。

### 2. エラーハンドリング

フック関数内でエラーが発生すると、mkarchiso はビルドを中断します。

### 3. 関数の読み込み

インジェクション関数は `profiledef.sh` から読み込まれている必要があります。
別ファイルに分割する場合は、`profiledef.sh` 内で `source` してください。
