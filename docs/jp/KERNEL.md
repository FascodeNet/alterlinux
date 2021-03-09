## カーネルの設定ファイルについて

AlterISOは様々なカーネルをサポートしています。カーネルは各アーキテクチャごとの設定ファイルで定義されます。


### 1.リポジトリを作成する
リポジトリには2種類のパッケージを追加する必要があります。カーネル本体とheadersパッケージです。  
`build.sh`はカーネルをpacmanを利用してインストールしようとします。もしあなたが公式リポジトリに無いカーネルを追加したい場合はまずはpacmanのリポジトリを作成してください。  
カーネルのパッケージをAURからビルドすることはできません。（`pacstrap`で初期の段階でインストールされるため。）


### 2.カーネル設定ファイルを構成する

`kernel-<arch>`はカーネルの設定の一覧が書かれたファイルです。構文は以下の通りになっており、`build.sh`によって解析されます。  
`#`から始まる行はコメントとして扱われます。1行で一つのカーネルの設定です。  

```bash
#[kernel name]               [kernel filename]               [mkinitcpio profile]
#

core                         vmlinuz-linux                   linux
lts                          vmlinuz-linux-lts               linux-lts
zen                          vmlinuz-linux-zen               linux-zen
```

#### kernel name
`build.sh`の`-k`によって指定される文字列です。絶対に重複しないようにしてください。  

#### kernel filename
`/boot`以下に作成されるバイナリのファイル名です。Calamaresの設定などのあらゆる場所で使用されます。

#### mkinitcpio profile
`mkinitcpio`の`-p`で指定するプロファイル名です。

### 3.カーネル用パッケージリストを作成する
実際のカーネルパッケージやヘッダーパッケージは専用のパッケージリストに記述して下さい。  
詳細は[PACKAGE.md](./PACKAGE.md)を参照してください。  


### 4.プルリクエストを送る
[ここ](https://github.com/FascodeNet/alterlinux/pulls)へプルリクエストを投稿してください。  

