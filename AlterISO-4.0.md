## AlterISO 4.0について

ベースとなるArchisoのバージョン更新を容易にするためAlterISOそのものにビルド機能を実装するのではなく、フォークされたArchiso(archiso-alter)にビルドを行わせる。

archiso-alterはArchiso 44以降の`profile`と互換性のあるconfigをベースにLiveCDのビルドを行う。（≒独自仕様を極力排除する）

しかしPlymouthや言語、モジュールの切り替えなどの過去のAlterISOの機能を削除するとソースコードの管理が非常に面倒になるため、AlterISO 4.0は「archiso-alterのprofileをビルドするためのラッパー」として動作させる。

将来的にはこのリポジトリには直接ビルドを行うコードを完全に排除し、低レベルなコードはすべてarchiso-alterに移行する。

archiso-alterでは既存の関数の改変を極力避け、新しい関数を挿入することで追加機能を実装する。

将来的にはAlterISOをシェルスクリプト以外の言語で実装することも可能になる。

### 概要
- 実際のビルドのコードはarchisoに依存させる
- PlymouthやAURなどの独自機能のパッチを当てた`archiso-alter`を作成しコア機能を分離
- 2024年中盤の完成を目指す

### 現在の進捗状況
  - [ ] AlterISO 3.1の機能をarchiso-alterに実装する
    - [ ] AlterISO 3.1独自の機能
      - [ ] `-b`: Boot Splash Plymouth (`boot_splash` `theme_name`)
    - [ ] ArchISOから構造が変更された機能
      - [ ] BuildMode
        - [ ] `--tarball`: Bootstrap Tarball (`tarball` `tar_comp` `tar_comp_opt`)
        - [ ] `--comp-typr`: Compressors Type (`sfs_comp` `sfs_comp_opt`)
      - [ ] BootMode
        - [ ] `--noefi`: Build without EFI (`noefi`)
        - [ ] `--noiso`: Build without ISO (`noiso`)
- [ ] `/system/`の各アーキテクチャのファイルを整理する
- [ ] ドキュメントを整理する
- [ ] モジュールの依存関係を実装 (参考: [FasBashLibの依存関係解決](https://github.com/Hayao0819/FasBashLib/blob/dev-0.2.x/lib/SolveRequire.sh))

## 当分のあいだの開発目標

archiso-alterで手動で書いたprofileをビルドできるようにする。

その後、channelやmoduleをprofileへまとめるスクリプトを書く。


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


## AlterISO 4.0 内部仕様の変更点

- `legacy_mode`の廃止

