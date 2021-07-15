## カーネルの設定ファイルについて
AlterISOは様々なカーネルをサポートしています。カーネルは各アーキテクチャごとの設定ファイルで定義されます。
ここではAlterISOに新しいカーネルのサポートを追加する方法を説明します。  
AlterISO全体ではなくチャンネル内部でのみ追加する方法は[チャンネルで独自に新しいカーネルをサポートする](ORIGINAL_KERNEL.md)を参照してください。  


### 1.リポジトリを作成する
AlterISO3ではカーネルをAURからインストールすることはできなかったため、リポジトリを構築する必要がありました。3.1からはAURによるカーネルパッケージリストがサポートされたため、その必要はなくなっています。  


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

