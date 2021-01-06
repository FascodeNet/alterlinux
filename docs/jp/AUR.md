## AURについて
AlterISO 3ではAURのパッケージをビルドに含めることができます。公式パッケージのインストールが終わった後、chrootでビルド用の一般ユーザーが作成されてビルドされます。初期のAlter ISO3では`makepkg`を使用してインストールを行っていましたが、現在は`yay`を使用してインストールされます。

## yayについて
yayはAlter Linuxのリポジトリからインストールされます。もしチャンネルで`alter-stable`リポジトリを無効化している場合は何なかの方法でyayをインストールするか、AURビルドを無効化する必要があります。

## AURビルドを無効化する
チャンネルの`config.<arch>`かビルド時に`--noaur`を指定することでAURのビルドをスキップできます。  
`config.<arch>`に以下を追記して下さい。

```bash
# Do not install the AUR package.
noaur=true
```
