## 日本語

### 新しいカーネルに対応させる

Alter Linuxを新しいカーネルに対応させる手順です。ここでは`linux-fooo`を追加する手順を説明します。実際に行う場合はこの文字を置き換えてください。  
リポジトリには2種類のパッケージを追加する必要があります。カーネル本体とheadersパッケージです。  


#### 1.リポジトリを作成する

`build.sh`はカーネルをpacmanを利用してインストールしようとします。もしあなたが公式リポジトリに無いカーネルを追加したい場合はまずはpacmanのリポジトリを作成してください。  
リポジトリはGitHubを利用して簡単に作成できます。  

#### 2.カーネル一覧に追加する

`kernel_list`にカーネル名を追記してください。`build.sh`に渡された値が正しいかどうかはこの変数を利用して判定されます。  
リストに追加する値は`linux-`の後の文字です。今回の場合は`fooo`になります。

```bash
echo "fooo" >> ./kernel_list
```

#### 3.ファイルを作成する
そのカーネル用のファイルを6つ作成する必要があります。以下はカーネルの一覧です。  
「既存のファイルを名前を変えてコピーし、カーネルへのパスを修正する」という方法が最も簡単です。  
ファイル名は`fooo`に置き換えてあります。  
- syslinux/archiso_sys/archiso_sys-fooo.cfg
- syslinux/archiso_pxe/archiso_pxe-fooo.cfg
- efiboot/loader/entries/cd/archiso-x86_64-cd-fooo.conf
- efiboot/loader/entries/usb/archiso-x86_64-usb-fooo.conf
- airootfs/usr/share/calamares/modules/unpackfs/unpackfs-fooo.conf
- airootfs/usr/share/calamares/modules/initcpio/initcpio-fooo.conf

##### archiso_sys-fooo.cfg

9行目のパスを変更してください。

##### archiso_pxe-fooo.cfg

9行目、20行目、31行目のパスを変更してください。

##### archiso-x86_64-cd-fooo.conf

2行目のパスを変更してください。

##### archiso-x86_64-usb-fooo.conf

2行目のパスを変更してください。

##### unpackfs-fooo.conf
95行目、97行目のパスを変更してください。

##### initcpio-fooo.conf
18行目のパスを変更してください。

#### 4.プルリクエストを送る
[ここ](https://github.com/SereneTeam/alterlinux/pulls)へプルリクエストを投稿してください。  

