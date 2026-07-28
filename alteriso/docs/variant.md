<!-- LLM Generated: Created by Claude -->

# バリアント

バリアントは、プロファイルとモジュールの上に重ねる差分です。日本語入力、特定のハードウェア向け
設定のように、一つのモジュールに閉じず複数のモジュールへまたがって効く変更を扱います。
プロファイル側の設定は [config.md](config.md)、モジュール側は [module.md](module.md) を
参照してください。

## 配置

バリアントは、それを提供するモジュールまたはプロファイルの中に置きます。

```text
modules/<name>/variants/<variant>/
configs/<name>/variants/<variant>/
```

中身はモジュールと同じ形式です。`packages*`、`airootfs*`、`alteriso.json` を置けます。

```text
configs/xfce/variants/japanese/
├── alteriso.json               # 任意
├── packages.x86_64
└── airootfs.any/
    └── etc/environment.d/fcitx.conf
```

一つのバリアント名を複数のソースが提供できます。`--variant japanese` を指定すると、
`japanese` を持つモジュールとプロファイルのすべてが適用されます。どのソースも
そのバリアントを持っていない場合は生成が失敗します。

## 適用順

バリアントはベース層をすべて敷いたあとに重ねます。

```text
モジュール1, モジュール2, ..., プロファイル,          ← ベース層
モジュール1:variantA, ..., プロファイル:variantA,     ← バリアント層
モジュール1:variantB, ..., プロファイル:variantB
```

後に適用したものが同じパスのファイルを上書きします。バリアントがプロファイル自身の設定を
上書きできるのは、この順序を狙って選んだためです。

一方で、読み込み順が前のモジュールのバリアントも、プロファイルのベース設定より優先されます。
ベース側を編集しても反映されないときは、バリアントが同じファイルを持っていないか確認して
ください。どのソースがどのディレクトリを適用したかは、生成時のログに出ます。

複数指定した場合はコマンドラインに書いた順で、後ろのバリアントが勝ちます。

```bash
alteriso profile generate configs/xfce --variant japanese,nvidia
```

パッケージリストは和集合なので、この順序の影響を受けるのは airootfs のファイルと
`module_options` の値だけです。

## alteriso.json

バリアントの `alteriso.json` は任意です。ファイルを置くだけのバリアントには必要ありません。
省略した場合、対応アーキテクチャは所有者から引き継ぎます。

シェルスクリプトを実行したい場合は必須です。`load_scripts` に書かれたスクリプトだけが
`profiledef.sh` へ埋め込まれるため、マニフェストのないディレクトリに置いた `*.sh` は
読み込まれません。この状態は生成時に警告します。

モジュールと同じフィールドに加えて、`module_options` を書けます。

```json
{
    "manifest_version": 1,
    "module_version": 1,
    "append_kernel_param": ["lang=ja"],
    "module_options": {
        "user": {
            "usershell": "/usr/bin/zsh"
        }
    }
}
```

`module_options` はプロファイルの値の上に重なります。バリアントに設定値を持たせるための
フィールドで、ファイルの差分だけでは表せない指定に使います。

## ファイルの持ち方

airootfs のマージはファイル単位です。設定を 1 項目だけ変えたい場合でも、同じパスに置けば
ファイル全体を置き換えることになり、ベース側の更新に追従できなくなります。

drop-in で書けるものは drop-in にしてください。`/etc/environment.d/`、
`/etc/systemd/*.conf.d/`、`/etc/skel/` 以下の独立したファイルなどが該当します。

drop-in の仕組みがない設定ファイル（xfconf の XML など）は、ファイルごと複製するより、
バリアントの `module.sh` で該当箇所だけ書き換えるほうが、ベース側の変更に追従できます。

## 記録

選択したバリアントは、生成後の `profiledef.json` と `alteriso.json` の `variants` に
指定順で残ります。ISO のファイル名にも付きますが、こちらは指定順によらず同じ名前になるよう
ソートした名前を使います。

```bash
alteriso profile generate configs/xfce --variant nvidia,japanese
# iso_name は alterlinux-japanese-nvidia
```

## 一覧の確認

```bash
alteriso profile variants configs/xfce
```

```text
japanese  fonts, xfce
```

左がバリアント名、右がそれを提供するソースです。あるバリアントを新しいモジュールへ広げたい
場合は、ここに出てくるソースを見て、足りないものを追加します。
