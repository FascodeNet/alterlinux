# alteriso

## alteriso 1.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-1>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/alteriso-1/docs>

archiso v43 の releng をフォークした最初のバージョンです。

## alteriso 2.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-2>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/alteriso-2/docs>

alteriso 1.0 をさらに拡張し、32 ビットのサポートを追加しました。

## alteriso 3.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-3.0>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/alteriso-3.0/docs>

言語サポートの強化やプロファイルの仕様変更が行われました。

## alteriso 3.1

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-3.1>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/alteriso-3.1/docs>

alteriso 3 と互換性を維持しながらモジュール機構を導入しました。

## alteriso 4.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-4.0>

大量の変更が加わった結果、上流である archiso への追従が難しくなりました。その対処として、
従来のコードベースを破棄し、実際のビルドを archiso に委任することを試みた最初のバージョンです。

この手法では alteriso 3.0 の設定ファイルを archiso 形式へ変換することを試みましたが、諸般の
事情により完成しませんでした。

## alteriso 5.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/3a11cb93f56a605b5da71dcf2106039991cc714d>

archiso への追従をやめ、Go でビルドツールを一から再実装することを試みました。

最低限のビルドは行えるようになりましたが、こちらも実装の煩雑さと諸般の事情により放棄されました。

## alteriso 6.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/dev>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/dev/alteriso/docs>

alteriso 4.0 の思想を受け継ぎ、archiso 用のプロファイルを生成する方式を再度採用しました。

archiso が `profiledef.sh` を `source` する仕組みを利用して mkarchiso の処理を拡張する
インジェクション機構を実装し、archiso への変更を最小限に抑えながら柔軟な機能拡張を可能に
しています。
