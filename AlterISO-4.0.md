## AlterISO 4.0について
以下にAlterISO 4.0の今後の開発方針を示す。

- チャンネル、モジュールの構成は維持
- Archiso 58に準拠し、少しずつbuild.shを書き直す
  - [x] 最初はAlterISO 3.1のコードを残しつつ、Archisoのコードを無理やり追加してビルドが通るようにする
  - [ ] ある程度のコードが固まったら余分な部分の削除を行う
  - [ ] AlterISO 3.1の機能を再実装する
  - [ ] Archisoからの変更を最小限にするために再実装
- [x] 関数名を整理する
- [ ] `tools`にある`build.sh`からしか呼び出されない外部コマンドを削除し、関数として再実装(※1)
  - [x] `/tools/kernel.sh` -> `/lib/kernel.sh`
  - [x] `/tools/locale.sh` -> `/lib/locale.sh`
  - [x] `/tools/alteriso-info.sh` -> `/lib/alteriso-info.sh`
  - [x] `/tools/module.sh` -> `/lib/module.sh`
  - [x] `/tools/channel.sh` -> `/lib/channel.sh`

- [x] `mkinitcpio-archiso`との統合は行わず、引き続き`/system/initcpio`を使用する(※2)
- [ ] `/system/`の各アーキテクチャのファイルを整理する
- [ ] ~~カーネルパラメータを統一し、現在boot_splashの有無で分かれているEFIやSyslinuxの設定ファイルを統一する~~
- [ ] menuconfigのディレクトリ構成を整理する
- [ ] ドキュメントを整理する
- [ ] 2022年後半の完成を目指す
- [ ] kokkiemouse主導だった旧AlterISO-4は`obs_alteriso-4`に変更。
- [ ] モジュールの依存関係を実装


## 当分のあいだの開発目標
当分の間はArchisoのコードを少しずつ取り込んでいく。  

## tools内のスクリプトについて
### 変更なし・現状を維持
- `/tools/build_helper.py`
- `/tools/docker-build.sh`
- `/tools/fullbuild.sh`
- `/tools/keyring.sh`
- `/tools/msg.sh`
- `/tools/package.py`
- `/tools/run_archiso.sh`
- `/tools/umount.sh`
- `/tools/wizard.sh`

### /libへ再実装
上記を参照

### /libへの移行を検討中
- `/tools/pkglist.sh`
- `/tools/clean.sh`

### menuconfig用につき別の場所へ移動予定
- `/tools/menuconf-to-alterconf.sh`
- `/tools/kernel-choice-conf-gen.sh`
- `/tools/channel-choice-conf-gen.sh`


## 注脚
### ※1
AlterISO 2.0時代に外部コマンドとして実装下のは名前区間の汚染を防ぐためだった。  
速度の低下や変数名の統一、余分なコードが増加したため、これらを書き直す。  
ライブラリ（関数を定義したシェルスクリプト）として実装し`build.sh`から`source`を行う。  
ユーザーが直接実行する`wizard.sh`や`clean.sh`などはそのまま`tools`として維持する。  
`module.sh`や`pkglist.sh`は関数として書き直し、`/lib`に移動する。  
また、Pythonなどの別言語で書かれているコードも`tools`にそのまま維持する。 

### ※2
上流の設定ファイルを使用すると今後のカスタマイズが困難になるため。  
