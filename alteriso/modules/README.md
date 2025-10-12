# AlterISO Modules

archisoに関数を挿入し、機能を追加します。

また、archisoの内部動作に強く依存するコードをカプセル化し、configの互換性と柔軟性を高めます。

## API

### airootfs

profileと同じ仕様です。

### packages.<arch>

profileと同じ仕様です。

### *.sh

[`mkarchiso`](../../archiso/mkarchiso)及び読み込まれている`profiledef.sh`で定義されている全てのシンボルを参照可能です。

また、ヘルパーとして[`injects`](../src/internal/archiso/injects/)内で定義されている関数にもアクセス可能です。

他のプロファイルやモジュールとのコンフリクトを防ぐため、Injectableな関数は定義しないでください。
