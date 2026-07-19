<!-- LLM Generated: This document was created by Codex -->

# 使い方

alteriso は入力プロファイルから単一アーキテクチャの archiso プロファイルを生成し、必要なら
そのまま mkarchiso を実行します。入力形式は [config.md](config.md)、モジュールの作成方法は
[module.md](module.md) を参照してください。

## ソースツリーから実行する

`alteriso/` をカレントディレクトリにした例です。

生成結果を確認するだけなら、補助スクリプトを使えます。

```bash
./gen.sh configs/minimum
```

ISO まで構築する場合は次を実行します。

```bash
./build.sh configs/xfce
```

どちらも Go バイナリを一時的にビルドし、リポジトリ内の `bootloaders/` と `modules/` を
指定します。`build.sh` は `sudo` と mkarchiso を使用し、正常終了時に作業ディレクトリを
削除します。

## alteriso コマンド

インストール済みバイナリの既定値は次のとおりです。

- モジュール: `/usr/share/alteriso/modules/`
- ブートローダー: `/usr/share/alteriso/bootloaders`
- ISO 出力: `./out`
- 作業ディレクトリ: `./work`

ソースツリーを直接使う場合は補助スクリプトを使うか、明示的にパスを指定します。

```bash
go run ./src profile \
    --modules ./modules \
    --bootloaders ./bootloaders \
    generate \
    --out ./out/minimum \
    ./configs/minimum
```

### `profile generate`

```text
alteriso profile generate [--out DIR] CONFIG
```

alteriso プロファイルを mkarchiso 用ディレクトリへ変換します。`CONFIG` は必須です。出力先は
`--out` で指定でき、既定値は `./out` です。既存の出力ディレクトリは拒否されます。
`generate` は `gen` でも呼び出せます。

主な生成物は次のとおりです。

```text
<out>/
├── profiledef.sh
├── profiledef.json
├── injecter.sh
├── alteriso.json
├── packages.<arch>
├── bootstrap_packages.<arch>
├── pacman.conf
├── airootfs/
└── <bootloader>/
```

入力に該当する内容がなければ、`airootfs/` や一部のブートローダー成果物は作られません。

### `profile build`

```text
alteriso profile build [--out DIR] [--work DIR] [CONFIG]
```

作業ディレクトリ内へプロファイルを生成してから mkarchiso を実行します。`CONFIG` を省略した
場合は `./configs/xfce` です。Pacman のキャッシュには `<work>/pacman_cache` を使用します。

### `profile` 共通オプション

| オプション | 説明 |
| --- | --- |
| `--modules DIR` | モジュールディレクトリ |
| `--bootloaders DIR` | ブートローダーのテンプレートディレクトリ |
| `--arch ARCH` | `profiledef.json` の既定ターゲットを今回だけ上書き |
| `--noconfirm` | 生成した `profiledef.sh` によるビルド前の確認を省略 |

`--arch` を変えて同じ入力から複数回生成できますが、出力先はアーキテクチャごとに分けてください。

```bash
./gen.sh configs/minimum --arch i686
```

### `clean`

```text
alteriso clean [--workdir DIR]
```

対象以下のマウントを解除して作業ディレクトリを削除します。ファイルシステムのルート、
カレントディレクトリ、ホームディレクトリは対象にできません。

リポジトリの `clean.sh` も `alteriso/work` をアンマウントして削除するためのスクリプトです。
`out/` は削除しません。

### `test-injectable`

```text
alteriso test-injectable
```

最小プロファイルで mkarchiso のインジェクション対応を検査します。非対応の場合は
`archiso is not injectable` を返し、終了コードは非ゼロです。

### `install-archiso`

インジェクション対応の mkarchiso を配置します。archiso パッケージが導入済みなら mkarchiso
スクリプトをダウンロードし、未導入ならソースリポジトリからインストールします。ネットワーク通信を
行い、既定では `/usr/local/bin/mkarchiso` またはシステム上のスクリプトを変更します。
ソースからのインストールには root 権限が必要です。

### `repo`

第三者リポジトリの設定スクリプトをダウンロードして実行します。root 権限とネットワーク接続が
必要で、システムのリポジトリ設定を変更します。現在は取得内容のダイジェストや署名を検証しません。

### `profile format`

コマンドは予約されていますが、フォーマッターは未実装です。現在は常に非ゼロで終了します。

## よくある失敗

- プロファイルの JSON とアーキテクチャの検証: [config.md](config.md#検証)
- モジュールのマニフェスト、パッケージ、オーバーレイ、インジェクション: [module.md](module.md)
- mkarchiso がインジェクション非対応: `alteriso test-injectable`
- パッケージが見つからない: 選択された Pacman 設定と対象リポジトリを確認
