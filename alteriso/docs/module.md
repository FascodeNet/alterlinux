<!-- LLM Generated: This document was created by Codex -->

# モジュール仕様

この文書は `modules/<name>/` の形式とマージ規則を説明します。プロファイル側の設定は
[config.md](config.md)、コマンドの使い方は [usage.md](usage.md) を参照してください。

## 構成

```text
modules/<name>/
├── alteriso.json
├── module.sh
├── packages
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
└── airootfs.<arch>/
```

`alteriso.json` は必須です。それ以外はモジュールが提供する機能に応じて追加します。

## alteriso.json

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `manifest_version` | number | はい | 現在は `1` のみ |
| `arch` | `"any" \| string[]` | はい | 対応アーキテクチャ |
| `module_version` | number | いいえ | メタデータ。未指定時は `0` |
| `load_scripts` | string[] | いいえ | モジュール内から埋め込むシェルスクリプト |
| `injects` | object (`map[string][]string`) | いいえ | mkarchiso のインジェクションフック |
| `append_kernel_param` | string[] | いいえ | ブートローダーへ追加するカーネルパラメーター |

最小構成は次のとおりです。

```json
{
    "manifest_version": 1,
    "arch": "any"
}
```

### arch

アーキテクチャに依存しない場合だけ文字列 `"any"` を使います。

```json
{
    "arch": "any"
}
```

対応範囲を限定する場合は、具体的な名前を一つ以上含む配列にします。

```json
{
    "arch": ["x86_64", "i686"]
}
```

次は不正です。

- `"arch": "x86_64"`
- `"arch": []`
- `"arch": ["any"]`
- 空文字列、前後に空白がある値、重複した値

マニフェストの読み込み時に形式を検証し、生成対象を選んだ後に対応可否を検証します。

## パッケージリスト

次の3種類をすべて読み込みます。

- `packages` と `packages.d/*`: 拡張子なし
- `packages.any` と `packages.any.d/*`: 全アーキテクチャ
- `packages.<arch>` と `packages.<arch>.d/*`: 選択したアーキテクチャ
- 同じ命名規則の `bootstrap_packages*`

書式は一行一パッケージです。空行と、空白を除いた後に `#` で始まる行は無視します。
プロファイルと選択された全モジュールの内容を統合し、重複を除いて名前順に出力します。
`.d/` 内のファイル名と拡張子には意味を持たせていません。

## airootfs

- `airootfs/`: 拡張子なしの共通レイヤー
- `airootfs.any/`: 明示的な全ターゲット共通レイヤー
- `airootfs.<arch>/`: 選択したターゲット専用レイヤー

コピー順は次のとおりで、後の内容が同じパスを上書きします。

1. `modules` 配列順に、各モジュールの `airootfs/`、`airootfs.any/`、`airootfs.<arch>/`
2. プロファイルの `airootfs/`、`airootfs.any/`、`airootfs.<arch>/`

存在しないディレクトリは省略できます。現在の実装では、存在するオーバーレイのコピーに
失敗しても警告だけを出して処理を継続します。この挙動は既知の未解消事項です。

## load_scripts

`load_scripts` はモジュールディレクトリからの相対パスです。各スクリプトはモジュール順に
読み込まれ、シバンを除いて生成後の `profiledef.sh` へ埋め込まれます。ファイルが存在しない場合や
シェル構文を解析できない場合は生成が失敗します。

```json
{
    "load_scripts": ["module.sh"]
}
```

スクリプトからは、mkarchiso のシンボルと alteriso ローダーのヘルパーを参照できます。
プロファイル情報のヘルパーは
[config.md](config.md#生成された-profiledefjson-の参照) にまとめています。

## インジェクション

`injects` のキーはインジェクション対応の mkarchiso が解釈するフックのシンボル、値は実行する
関数名の配列です。

```json
{
    "injects": {
        "post__make_packages": [
            "example_after_packages"
        ]
    }
}
```

同じフックに複数のモジュールが登録した場合、`profiledef.json` の `modules` 順に連結し、最後に
プロファイル側の `injects` を加えます。フック名や関数の存在は Go 側では検証しないため、対象の
mkarchiso にある関数名と一致させてください。

`require_injectable` が `false` なら、インジェクション非対応の mkarchiso では互換モードとして
インジェクションを無効化できます。`true` ならインジェクション非対応の mkarchiso で停止します。

## カーネルパラメーター

全モジュールの `append_kernel_param` をモジュール順に連結し、重複を除いて
`%ALTERISO_KERNEL_PARAM%` へ展開します。

```json
{
    "append_kernel_param": ["quiet", "splash"]
}
```

## 組み込みモジュール

対応範囲や実装は各ディレクトリの `alteriso.json` を正とします。固定の一覧を文書へ複製すると
更新漏れが生じるため、[modules/](../modules/) を直接参照してください。
