## 新しいカーネルに対応させる

Alter Linuxを新しいカーネルに対応させる手順です。ここでは`linux-fooo`を追加する手順を説明します。実際に行う場合はこの文字を置き換えてください。  
リポジトリには2種類のパッケージを追加する必要があります。カーネル本体とheadersパッケージです。  


### 1.リポジトリを作成する

`build.sh`はカーネルをpacmanを利用してインストールしようとします。もしあなたが公式リポジトリに無いカーネルを追加したい場合はまずはpacmanのリポジトリを作成してください。  
リポジトリはGitHubを利用して簡単に作成できます。  

### 2.カーネル一覧に追加する

`kernel_list`にカーネル名を追記してください。`build.sh`に渡された値が正しいかどうかはこの変数を利用して判定されます。  
リストに追加する値は`linux-`の後の文字です。今回の場合は`fooo`になります。

```bash
echo "fooo" >> ./system/kernel_list
```

### 3.ファイルを作成する
新しいカーネル用のファイルをいくつか作成する必要があります。以下は作成する必要のあるファイルの一覧です。  
「既存のファイルを名前を変えてコピーし、カーネルへのパスを修正する」という方法が最も簡単です。  
ファイル名は`fooo`に置き換えてあります。  

1. syslinux/x86_64/pxe/archiso_pxe-fooo.cfg
2. syslinux/i686/pxe/archiso_pxe-fooo.cfg
3. syslinux/x86_64/pxe-plymouth/archiso-fooo.cfg
4. syslinux/i686/pxe-plymouth/archiso-fooo.cfg
5. syslinux/x86_64/sys/archiso_sys-fooo.cfg
6. syslinux/i686/sys/archiso_sys-fooo.cfg
7. syslinux/x86_64/sys-plymouth/archiso_sys-fooo.cfg
8. syslinux/i686/sys-plymouth/archiso_sys-fooo.cfg
9. efiboot/loader/entries/cd/archiso-x86_64-cd-fooo.conf
10. efiboot/loader/entries/usb/archiso-x86_64-usb-fooo.conf
11. channels/share/airootfs.any/usr/share/calamares/modules/unpackfs/unpackfs-fooo.conf
12. channels/share/airootfs.any/usr/share/calamares/modules/initcpio/initcpio-fooo.conf

これらのファイルはインストーラやブートローダのファイルです。各カーネル用にパスを修正して下さい。  

### 4.プルリクエストを送る
[ここ](https://github.com/FascodeNet/alterlinux/pulls)へプルリクエストを投稿してください。  

