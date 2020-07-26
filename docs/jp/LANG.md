# 多言語化について
以前までのAlterISO 2では、グローバル版か日本語版しか選択がおこなせませんでした。しかし、AlterISO 3になって様々な言語に対応しました。  
以下は新しい言語を追加する方法とその仕様に関するドキュメントです。  

# ドキュメントの見方
`<arch>`はビルド時のアーキテクチャ名、`<locale>`は言語名、`<ch_name>`はチャンネル名に置き換えてください。  

# 言語リストについて
言語リストとは、ビルドに使用できる言語の設定を書いたファイルです。  
`system/locale-<arch>`が言語リストとして認識されます。  
言語リストは以下の構文で記述して下さい。

```
# <locale name> <locale.gen> <archlinux mirror> <lang version name> <timezone> <fullname>

# Global version
gl      en_US.UTF-8      all    gl     UTC         global

# Japanese
ja      ja_JP.UTF-8      JP     ja     Asia/Tokyo  japanese

# English
en      en_US.UTF-8      US     en     UTC         english
```

## 基本構文とコメント
`#`から始まる行はコメントとして扱われます。データは空白で区切られ、左からデータの内容が決められています。  

## locale name
`locale_name`は言語用パッケージの一覧やビルド時の指定で使用されます。基本的に制限はありませんが、わかりやすく短い名前がいいでしょう。  
言語名が重複することはスクリプトで考慮されていないので重複は絶対に避けて下さい。  

## locale.gen
`/etc/locale.gen`でコメントアウトする値です。テキストエンコーディング（`ja_JP.UTF-8 UTF-8`の` UTF-8`の部分）は記述しないで下さい。  
  
## archlinux mirror
[Mirrorlist Generator](https://www.archlinux.org/mirrorlist/)のURLの`/?country=`の後の文字列です。  
ArchLinux32とArchLinuxでは文字列が異なるので注意してください。  

## lang version name
イメージファイルのファイル名に使用される言語の名前です。よほどの事情が無い限り`locale name`と同じで良いでしょう。  

## timezone
ライブ環境のタイムゾーンの設定です。`/usr/share/zoneinfo`以下のパスを記述して下さい。

## fullname
その言語のフルネームです。ビルド時のメッセージ等に使用されます。