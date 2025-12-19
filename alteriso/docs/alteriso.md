# alteriso

## alteriso 1.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-1>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/alteriso-1/docs>

archiso v43のrelengをフォークした最初のバージョンです。

## alteriso 2.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-2>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/alteriso-2/docs>

alteriso 1.0を更に拡張し、32bitのサポートを追加しました。

## alteriso 3.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-3.0>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/alteriso-3.0/docs>

言語サポートの強化やプロファイルの仕様変更が行われました。

## alteriso 3.1

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-3.1>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/alteriso-3.1/docs>

alteriso 3と互換性を維持しながらモジュール機構を導入しました。

## alteriso 4.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/alteriso-4.0>

大量の変更が加わった結果、上流であるarchisoへの追従が難しくなったことへの対処として、従来のコードベースを破棄し実際のビルドをarchisoに委任させることを試みた最初のバージョンです。

この手法はalteriso 3.0の設定ファイルをarchiso形式のものへ変換することを試みましたが、諸般の事情により完成しませんでした。

## alteriso 5.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/3a11cb93f56a605b5da71dcf2106039991cc714d>

archisoへの追従を破棄しGo言語でビルドツールを一から再実装することを試みました。

最低限のビルドは行えるようになりましたが、こちらも実装の煩雑さと諸般の事情により放棄されました。

## alteriso 6.0

ソースコード: <https://github.com/FascodeNet/alterlinux/tree/dev>
ドキュメント: <https://github.com/FascodeNet/alterlinux/tree/dev/alteriso/docs>

alteriso 4.0の思想を受け継ぎ、archiso用のプロファイルを生成する方式を再度採用。

archisoが`profiledef.sh`を`source`することを利用してmkarchisoの処理を改変するInject機構を実装することで、archisoへの変更を最小限に抑えながら柔軟な機能拡張を可能にしています。
