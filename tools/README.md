# Tools
Alter Linuxのビルドに使用する処理をコマンド化したものです。  
これらのスクリプトは相互に呼び出したり、`build.sh`から呼び出されたりします。  
コマンドラインから実行することも可能です。  

## allpkglist.sh
全てのチャンネルのパッケージの一覧を表示します。  
`channel.sh`でチャンネルの一覧を取得後、`pkglist.sh`でパッケージ一覧を取得します。

## build_helper.py
GUIのビルドヘルパーです。PyGobjectが必要です。  

## channel.sh
チャンネルの一覧や`description.txt`の取得、確認を行います。  
詳細は`channel.sh -h`を実行してください。  

## clean.sh
作業ディレクトリの削除を行います。  
詳細は`clean.sh -h`を実行してください。  

## docker-build.sh
DockerでAlterISO3のビルドを行います。  

## fullbuiuld.sh
条件に合致する全てのエディションのビルドを行います。  
新しいバージョンがリリースされる際のビルドはこのスクリプトが使用されます。  
詳細は`fullbuild.sh -h`を実行してください。  

## kernel.sh
カーネル設定ファイルの解析とその結果の出力、確認を行います。  
詳細は`kernek.sh -h`を実行してください。  

## kernel-choice-conf-gen.sh
menuconfigで使用されるスクリプトです。  

## keyring.sh
キーリングの追加と削除を行います。  

## locale.sh
言語設定ファイルの解析とその結果の出力、確認を行います。  
詳細は`locale.sh -h`を実行してください。

## menuconf-to-alterconf.sh
menuconfigで使用されるスクリプトです。  

## msg.sh
ラベルと色がついたメッセージを出力します。このスクリプトは様々な場所から呼び出されます。  
詳細は`msg.sh -h`を実行してください。  

## package.py
`package.sh`の代わりに開発されたものです。Pyalpを使用して引数に指定されたパッケージの状態を出力します。  
`build.sh`の依存関係チェックに使用されています。  
詳細は`package.py -h`を実行してください。

## pkglist.py
指定されたチャンネルのパッケージ一覧を取得します。  
詳細は`pkglist.sh`を実行してください。

## testpkg.sh
`allpkglist.sh`で全てのパッケージ一覧を取得後、そのパッケージが公式リポジトリから利用可能かどうかを調べます。  
詳細は`testpkg.sh`を実行してください。  

## wizard.sh
CLIの対話型のビルド設定ツールです。英語と日本語に対応しています。  
依存パッケージの自動インストールやキーリングの自動インストールを行います。  
一部のデバッグオプションには対応していません。  
詳細は`wizard.sh -h`を実行してください。  
