## パッケージリストについて

一部のパッケージはスクリプトによって自動でインストールされます。以下はそのパッケージのリストです。  
以下のパッケージはパッケージリストに追加する必要はありません。

- bash
- base
- haveged
- intel-ucode
- amd-ucode
- mkinitcpio-nfs-utils
- nbd
- efitools

以下のパッケージはビルドオプションや依存関係によってスクリプトが判断してインストールします。  
以下のパッケージは絶対にパッケージリストに記述しないでください。

- plymouthやその設定ファイルやテーマファイル
- linux kernel
- linux headers
- broadcom-wl
- broadcom-wl-dkms
  
2020年5月28日より、base-develはデフォルトでインストールされなくなりました。  
各チャンネルのパッケージとしてインストールする必要があります。  