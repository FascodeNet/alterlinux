## AlterISO 4.0について

### 概要
- チャンネル、モジュールの構成は維持
- Archiso 58に準拠し、少しずつbuild.shを書き直す
- Archisoからの変更を最小限にするために再実装
- 2022年後半の完成を目指す

### 現在の進捗状況
  - [x] 最初はAlterISO 3.1のコードを残しつつ、Archisoのコードを無理やり追加してビルドが通るようにする
  - [x] 関数名を整理する
  - [x] `mkinitcpio-archiso`との統合は行わず、引き続き`/system/initcpio`を使用する(※2)
  - [x] ~~カーネルパラメータを統一し、現在boot_splashの有無で分かれているEFIやSyslinuxの設定ファイルを統一する~~
  - [x] kokkiemouse主導だった旧AlterISO-4は`obs_alteriso-4`に変更。
  - [x] menuconfig用のスクリプトを別の場所へ移動
  - [x] `/tools/menuconf-to-alterconf.sh`
  - [x] `/tools/kernel-choice-conf-gen.sh`
  - [x] `/tools/channel-choice-conf-gen.sh`

  - [ ] ~~ある程度のコードが固まったら余分な部分の削除を行う~~
  - [ ] AlterISO 3.1の機能を再実装する(ロングオプションの大半は未実装)
    - [ ] AlterISO 3.1独自の機能
      - [ ] `-b`: Boot Splash Plymouth (`boot_splash` `theme_name`)
      - [ ] `dependance`: 依存関係の検証をパッケージベースからコマンド、ファイルベースに変更
        - [ ] `package.py`を削除
        - [ ] `pyalpm`依存を削除
        - [ ] Arch Linux依存の処理を削除
    - [ ] ArchISOから構造が変更された機能
      - [ ] BuildMode
        - [ ] `--tarball`: Bootstrap Tarball (`tarball` `tar_comp` `tar_comp_opt`)
        - [ ] `--comp-typr`: Compressors Type (`sfs_comp` `sfs_comp_opt`)
      - [ ] BootMode
        - [ ] `--noefi`: Build without EFI (`noefi`)
        - [ ] `--noiso`: Build without ISO (`noiso`)
- [ ] `tools`にある`build.sh`からしか呼び出されない外部コマンドを削除し、関数として再実装(※1)
  - [x] `/tools/kernel.sh` -> `/lib/kernel.sh`
  - [x] `/tools/locale.sh` -> `/lib/locale.sh`
  - [x] `/tools/alteriso-info.sh` -> `/lib/alteriso-info.sh`
  - [x] `/tools/module.sh` -> `/lib/module.sh`
  - [x] `/tools/channel.sh` -> `/lib/channel.sh`
  - [ ] `/tools/pkglist.sh` -> `/lib/pkglist.sh`
- [ ] `/system/`の各アーキテクチャのファイルを整理する
- [ ] menuconfigのディレクトリ構成を整理する
- [ ] ドキュメントを整理する
- [ ] モジュールの依存関係を実装 (参考: [FasBashLibの依存関係解決](https://github.com/Hayao0819/FasBashLib/blob/dev-0.2.x/lib/SolveRequire.sh))
- [ ] Archiso v58からv65への更新
  - [x] v58 to v59 ([Compare](https://github.com/archlinux/archiso/compare/v58...v59))
  - [x] v59 to v60 ([Compare](https://github.com/archlinux/archiso/compare/v59...v60))
  - [ ] v60 to v61 ([Compare](https://github.com/archlinux/archiso/compare/v60...v61))
  - [ ] v61 to v62 ([Compare](https://github.com/archlinux/archiso/compare/v61...v62))
  - [ ] v62 to v62.1 ([Compare](https://github.com/archlinux/archiso/compare/v61...v62.1))
  - [ ] v62.1 to v63 ([Compare](https://github.com/archlinux/archiso/compare/v62.1...v63))
  - [ ] v63 to v64 ([Compare](https://github.com/archlinux/archiso/compare/v63...v64))
  - [ ] v64 to v65 ([Compare](https://github.com/archlinux/archiso/compare/v64...v65))

## 当分のあいだの開発目標
~~ 当分の間はArchisoのコードを少しずつ取り込んでいく。 ~~
だいたい終わったので今後はソースコードの整理と安定化。

mkarchisoからの変更を最小限にするために無駄な部分も削除しない

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
- `/tools/clean.sh`

### /libへ再実装
上記を参照

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
