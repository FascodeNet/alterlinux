# チャンネルをAlterISO3用に書き換える

AlterISO3では様々な新機能が追加されました。そしてそれと同時に一部の仕様も変更されています。  

ここではAlterISO2用に開発されたチャンネルを3用に更新するための手順を説明します。  

## この文書の読み方

ここではチャンネル名を`<ch_name>`と表記しています。それぞれのチャンネルディレクトリに置き換えてください。  

## 1. バージョンファイルを作成する

`<ch_name>/alteriso`ファイルを作成し、中に`alteriso=3.0`と記述して下さい。  

このファイルが存在しないと以前のバージョン用のチャンネルと解釈され、ビルドできません。  

## 2. 日本語関連のコードを変更する

### config.<arch>

以前の`japanese`変数は意味を成しません。AlterISO3では言語名を`locale_name`変数で行っています。  
特定の言語を強制的に使用させたい場合は、`-l`オプションで指定する言語名を`locale_name`変数で指定して下さい。  

### モジュールについて
AlterISO 3.1用に開発する場合はモジュール一覧も定義する必要があります。  
詳細は後ほど追記します。

#### 詳細設定を行う
AlterISO3は`locale_name`の値を元にいくつかの変数を`system/locale-<arch>`から参照します。  
チャンネルの`config`ファイルでは変数を上書きできるので、これらを詳細に書き換えることができます。  
`locale.gen`の値は`locale_gen_name`変数、タイムゾーンは`locale_time`変数で設定できます。  
詳細は[releng](/channels/releng/config.any)を参考にして下さい。  


### customize_airootfs_<ch_name>.sh


引数解析部分が不要になりました。該当部分を削除してください。  
また、`remove`などの関数定義も不要になりました。  
利用可能な変数や関数は[share/customize_airootfs.sh](https://github.com/FascodeNet/alterlinux/blob/dev/channels/share/airootfs.any/root/customize_airootfs.sh)を参照してください。

##### 以前のコード

```bash
# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel='zen'
theme_name=alter-logo
rebuild=false
japanese=false
username='alter'
os_name="Alter Linux"
install_dir="alter"
usershell="/bin/bash"
debug=true


# Parse arguments
while getopts 'p:bt:k:rxju:o:i:s:da:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel="${OPTARG}" ;;
        r) rebuild=true ;;
        j) japanese=true;;
        u) username="${OPTARG}" ;;
        o) os_name="${OPTARG}" ;;
        i) install_dir="${OPTARG}" ;;
        s) usershell="${OPTARG}" ;;
        d) debug=true ;;
        x) debug=true; set -xv ;;
        a) arch="${OPTARG}"
    esac
done
```


#### 日本語用処理部分

日本語化のために、以前は`japanese`変数が`true`か`false`かで処理を分岐させていました。  

しかしAlterISO3では`japanese`変数は廃止されているため正常に処理を続行できません。  

代わりに`language`変数が`ja`に設定されているかどうかで処理を分岐させてください。  

##### 例

```bash

# 以前のコード

if [[ "${japanese}" = true ]]; then

# AlterISO3用のコード

if [[ "${language}" = "ja" ]]; then

```

## 3.パッケージリストのパスを変更する

多言語化に伴い`jp.<arch>`と`non-jp.<arch>`のパッケージリストは廃止されました。  

これらはAlterISOでは通常のパッケージリストと同等に扱われてしまいます。  

以前のように言語ごとのパッケージを追加する場合は`<ch_name>/packages.<arch>/lang/<lang_name>.<arch>`リストを使用して下さい。  
